module Util

    # Given an array, return a random element (actually looks like Array.sample does this)
    def Util.randomItem(list)
        if (list.class.to_s == "Array")
            return list[rand(list.length)]
        else
            puts "Expected randomItem takes an Array as an argument, not a #{list.class}"
        end
    end

    # Given a hash that maps objects to integers (frequency), return an array of up to the n most frequent objects
    def Util.getItemsWithMaxFreq(n, hash)
        if (hash.class.to_s != "Hash")
            puts "Util::getMaxFreq expects a Hash, not a #{hash.class}"
            return
        end
        if (hash.size < n)
            return hash.keys
        end
        finalList = []
        max = 0
        ceil = 9999999999  # assuming no frequencies higher than this...
        maxItems = []
        while (finalList.size < n)
            # find all occurances of the highest frequency (max) thats below ceil
            hash.each_pair do |k,v|
                if (v > max and v < ceil)
                    max = v
                    maxItems = [k]
                elsif (v == max)
                    maxItems.push(k)
                end
            end
            # add all these items to the final list, go back and do it again, but ceil
            # will be set to the max value so the second time through we'll get the second
            # most frequent items and so on
            maxItems.each do |item|
                finalList.push(item)
            end
            ceil = max
            max = 0
            maxItems = []
        end
        # once we have enough, take the first N items
        return finalList[0..(n-1)]
    end
    
    def Util.interpretPuncMarkup(line)
        line.gsub!(/\s*<start>\s*/, "")
        line.gsub!(/\s*<stop>\s*/, ". ")
        line.gsub!(/\s*<comma>\s*/, ", ")
        line.gsub!(/\s*<colon>\s*/, ": ")
        line.gsub!(/\s*<semicolon>\s*/, "; ")
        line.gsub!(/\s*<exclamation>\s*/, "! ")
        line.gsub!(/\s*<question>\s*/, "? ")
        line.gsub!(/\s*<dash>\s*/, " - ")
        while md = line.match(/(\s*<quote:(.*)>\s*)/)
            tag = md[1]
            q = md[2]
            q.gsub!(/_/, " ")
            line.sub!(/#{tag}/, " \"#{q}\" ")
        end
        while md = line.match(/(\s*<paren:(.*)>\s*)/)
            tag = md[1]
            q = md[2]
            q.gsub!(/_/, " ")
            line.sub!(/#{tag}/, " (#{q}) ")
        end
        line.gsub!(/\^/, ",")
        return line
    end
    
    def Util.addPuncMarkup(line, lineStartsSentance=1)
        line = line.force_encoding('ASCII-8BIT')
        
        return "" if (line.strip.empty?)  # blank lines should bail before we go adding a start tag
        
        # add a start tag to the beginning of each sentance
        line = "<start> " + line if (lineStartsSentance)
        
        # identify short quoted phrases as single words
        # Example: "best in test" -> <quote:best_in_test>
        #while (md = line.match(/["“](.{1,20})["”]/))
        # \x93=“  \x94=”
        while (md = line.match(/["#{147.chr}](.{1,20})["#{148.chr}]/))
            phrase = md[1]
            modPhrase = md[1].gsub(/ /, "_")
            line.gsub!(/["#{147.chr}]#{phrase}["#{148.chr}]/, "<quote:#{modPhrase}>")
        end

        # identify short parenthetical phrases as single words
        # Example: (best in test) -> <paren:best_in_test>
        while (md = line.match(/\((.{1,20})\)/))
            phrase = md[1]
            modPhrase = md[1].gsub(/ /, "_")
            line.gsub!(/\(#{phrase}\)/, "<paren:#{modPhrase}>")
        end
        
        # TODO: eventually we can include these as markup, but the language model should be smart enough
        # to pair a opening quote with a closing one, and an opening paren with a closing one
        line.gsub!(/["#{147.chr}#{148.chr}]/, "")   # ignore remaining quotes
        line.gsub!(/[\(\)]/, "")    # ignore remaining parens
        
        # change punctuation into markup - at end of line
        line.gsub!(/\.$/, " <stop>")
        line.gsub!(/\,$/, " <comma>")
        line.gsub!(/\:$/, " <colon>")
        line.gsub!(/\;$/, " <semicolon>")
        line.gsub!(/\!$/, " <exclamation>")
        line.gsub!(/\?$/, " <question>")
        # ...and midline
        line.gsub!(/\.\s+/, " <stop> ")   # "blah blah." => "blah blah <stop>"
        line.gsub!(/<stop>\s*([^\s])/, " <stop> <start> \\1")  # "blah. blah" => "blah <stop> <start> blah"
        line.gsub!(/\,\s+/, " <comma> ")
        line.gsub!(/\:\s+/, " <colon> ")
        line.gsub!(/\;\s+/, " <semicolon> ")
        line.gsub!(/\!\s+/, " <exclamation> ")
        line.gsub!(/\?\s+/, " <question> ")

        line.gsub!(/\s+(#{151.chr}|#{150.chr}|-)\s+/, " <dash> ")
        line.sub!(/^(<start>)?\s*#{183.chr}\t/, "<bullet> ")
        
        # replace remaining commas (in large numbers and such) to keep the csv file happy
        line.gsub!(/,/, "^")   
        
        line.strip!
        
        return line
    end
    
    def Util.getWordType(word, count)
        if (word.length > 1 and word.upcase == word)
            return "acronym"
        elsif (word[0] != "<" and word[0] == word[0].upcase and count > 0)
            return "properNoun"
        elsif (word.length > 1 and word =~ /[A-Z]/)
            return "mixedCaps"
        end
    end
    
    def Util.interpretWordType(word)
        if (md = word.match(/\{(.*?)\}/))
            type = md[1]
            word = word.gsub(/\{.*?\}/, "")
            word = word.upcase if (type == "acronym")
            word = word.capitalize if (type == "properNoun")
        end
        return word
    end
    
end
