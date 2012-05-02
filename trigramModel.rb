require './util'
require './markovModel'

class TrigramModel
    def initialize
        @unigram = MarkovModel.new
        @fwdBigram = SecondOrderMarkovModel.new
        @fwdTrigram = ThirdOrderMarkovModel.new
        @bkwdBigram = SecondOrderMarkovModel.new
        @bkwdTrigram = ThirdOrderMarkovModel.new
    end
    
    def addFile(file)
        lines = IO.readlines(file)
        skip = Hash.new
        prevWord = nil
        prevWord2 = nil
        lines.each do |line|
            line = line.force_encoding("ASCII-8BIT") if RUBY_VERSION =~ /1.9/
            line.gsub!(/\r/, "")
            
            words = line.split(/\s+/)
            count = 0
            words.each do |word|
                unless word =~ /[A-Za-z0-9\&]/
                    if not skip.has_key?(word)
                        puts "Skipping non-letter word #{word}"
                        puts line
                    end
                    skip[word] = 1
                    prevWord = nil
                    prevWord2 = nil
                end
                
                lcw = word.downcase
                wordType = Util.getWordType(word, count)
                lcw += "{#{wordType}}" if (wordType)
                lcw = word if (wordType == "mixedCaps")

                @unigram.addItem(lcw)
                unless prevWord.nil?
                    @fwdBigram.addItem(lcw, prevWord)
                    @bkwdBigram.addItem(prevWord, lcw)
                    unless prevWord2.nil?
                        @fwdTrigram.addItem(lcw, prevWord, prevWord2)
                        @bkwdTrigram.addItem(prevWord2, prevWord, lcw)
                    end
                end
                
                prevWord2 = prevWord
                prevWord = lcw
                if lcw == "<stop>"
                    prevWord = nil
                    prevWord2 = nil
                end
                
                count += 1
            end
        end
    end

    # returns a likely next word given a list of previous words, starting with the most recent
    def getLikelyNextWord(*prev)
        raise "No prev arguments provided!" if prev.length == 0
        raise "First prev argument is nil!" if prev[0].nil?
        word = nil
        # puts "prev0 is #{prev[0]}, prev1 is #{prev[1]}"
        unless prev[1].nil?
            # puts "trying the trigram"
            word = @fwdTrigram.getRandomItem(10, prev[0], prev[1])
        end
        if word.nil?
            # puts "trying the bigram"
            word = @fwdBigram.getRandomItem(10, prev[0])
            # puts "got word = #{word}"
        end
        if word.nil?
            puts "Using the unigram... shouldn't ever come to this!"
            word = @unigram.getRandomItem(10)
        end
        return word
    end
    
    def buildRandSentanceFromStart
        sentance = prev1 = "<start>"
        word = ""
        prev2 = nil
        count = 0
        
        until (word =~ /(<stop>|<question>|<exclamation>)/)
            word = getLikelyNextWord(prev1, prev2)
            prev2 = prev1
            prev1 = word
            word = Util.interpretWordType(word)
            sentance += " " + word
            count += 1
            break if (count == 1000)
        end
        
        sentance = Util.interpretPuncMarkup(sentance)
        sentance[0] = sentance[0].to_s.capitalize
        return sentance
    end
    
    def buildRandSentanceFromKeyword(keyword)
        # TODO
    end
    
    def printStats
        @unigram.printStats("wordlist.csv", "unigram")
        @fwdBigram.printStats("fwdBigramList.csv", "forward bigram")
        @fwdTrigram.printStats("fwdTrigramList.csv", "forward trigram")
        @bkwdBigram.printStats("bkwdBigramList.csv", "backward bigram")
        @bkwdTrigram.printStats("bkwdTrigramList.csv", "backward trigram")
    end

end
