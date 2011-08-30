class RCron
  module Parser
    # @param [String] cron Cron-format schedule string
    # @return [Hash] Parsed schedule
    def self.parse(cron)
      elements = cron.strip.split(/\s+/)
      raise ArgumentError.new("Invalid format: '#{cron}'") unless [5, 6].include? elements.length

      parser = lambda { |type, min, len, element, subs, extra|
        return nil if element.nil?

        max = min + len

        (subs || {}).each do |k, v|
          element = element.gsub(/\b#{k}\b/i, v.to_s)
        end

        ret = element.split(',').map { |e|
          err = ArgumentError.new("Invalid #{type} specification: '#{cron}'")
          case e
          when '*'
            nil
          when %r|^[0-9]+$|
            ei = e.to_i
            raise err if ei < min || ei > max
            ei
          when %r|^\*/([1-9][0-9]*)$|
            (min...max).select { |m| m % $1.to_i == 0 }
          when %r|^([0-9]+)-([0-9]+)$|
            f, t = $1.to_i, $2.to_i

            raise err if f < min || f > max
            raise err if t < min || t > max

            if f < t
              (f..t).to_a
            else
              (f...max).to_a + (min..t).to_a
            end
          else
            extra && extra.call(e) || raise(err)
          end
        }.flatten.compact.uniq.inject({}) { |h, k| 
          if k.is_a? Hash
            h[k.first.first] = k.first.last
          else
            h[k] = true
          end
          h 
        }
        ret.empty? ? nil : ret
      }

      schedule = {
        :minutes => parser.call('minute', 0, 60, elements[0], nil, nil),
        :hours => parser.call('hour', 0, 24, elements[1], nil, nil),
        :days => parser.call('day/month', 1, 31, elements[2], nil,
                  lambda { |e|
                    case e.upcase
                    when 'L'
                      -1
                    when /W/
                      raise NotImplementedError.new("Nearest weekday not implemeneted: '#{cron}'")
                    end
                  }),
        :months => parser.call('month', 1, 12, elements[3], 
                      { 'jan' => 1, 'feb' => 2, 'mar' => 3,
                        'apr' => 4,  'may' => 5, 'jun' => 6,
                        'jul' => 7, 'aug' => 8, 'sep' => 9,
                        'oct' => 10, 'nov' => 11, 'dec' => 12 }, nil),
        :weekdays => parser.call('day/week', 0,  7, elements[4], 
                      { 'sun' => 0, 'mon' => 1, 'tue' => 2,
                        'wed' => 3, 'thu' => 4, 'fri' => 5, 'sat' => 6 },
                      lambda { |e|
                        if e =~ /^([0-6]+)#([1-5])$/
                          {$1.to_i => $2.to_i}
                        end
                      }),
        :years => parser.call('year', 1970, 130, elements[5], nil, nil)
      }
      schedule
    end
  end#Parser
end#RCron

#puts RCron::Parser.parse('*/8 * */2,L * sun,wed#2')
