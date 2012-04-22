require './util'

class MultigramModel
    attr_accessor :uCount, :bCount, :tCount
    
    def initialize
        @unigram = {}
        @bigram = {}
        @trigram = {}
        #@bkwdBigram = Hash.new
        #@bkwdTrigram = Hash.new
        @uCount = 0
        @bCount = 0
        @tCount = 0
    end
    
    def addFile(file)
        lines = IO.readlines(file)
        skip = Hash.new
        prevWord = nil
        prevWord2 = nil
        lines.each do |line|
            line = line.force_encoding("ASCII-8BIT")
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

                if @unigram.has_key?(lcw)
                        @unigram[lcw] += 1
                else
                    @unigram[lcw] = 1
                    @uCount += 1
                end
                unless prevWord.nil?
                    if @bigram.has_key?(prevWord)
                        if @bigram[prevWord].has_key?(lcw)
                            @bigram[prevWord][lcw] += 1
                        else
                            @bigram[prevWord][lcw] = 1
                            @bCount += 1
                        end
                    else
                        @bigram[prevWord] = {}
                        @bigram[prevWord][lcw] = 1
                        @bCount += 1
                    end
                    unless prevWord2.nil?
                        if @trigram.has_key?(prevWord2)
                            if @trigram[prevWord2].has_key?(prevWord)
                                if @trigram[prevWord2][prevWord].has_key?(lcw)
                                    @trigram[prevWord2][prevWord][lcw] += 1
                                else
                                    @trigram[prevWord2][prevWord][lcw] = 1
                                    @tCount += 1
                                end
                            else
                                @trigram[prevWord2][prevWord] = {}
                                @trigram[prevWord2][prevWord][lcw] = 1
                                @tCount += 1
                            end
                        else
                            @trigram[prevWord2] = {}
                            @trigram[prevWord2][prevWord] = {}
                            @trigram[prevWord2][prevWord][lcw] = 1
                            @tCount += 1
                        end
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
    
    def getLikelyNextWord(prev1, prev2=nil)
        if (prev1.nil?)
            puts "Well you gotta give me something!"
            return nil
        end
        if (not prev2.nil? and @trigram.has_key?(prev2) and @trigram[prev2].has_key?(prev1))
            counts = @trigram[prev2][prev1]
            max10 = Util.getItemsWithMaxFreq(10, counts)
            return Util.randomItem(max10)
        elsif (@bigram.has_key?(prev1))
            counts = @bigram[prev1]
            max10 = Util.getItemsWithMaxFreq(10, counts)
            return Util.randomItem(max10)
        else
            max10 = Util.getItemsWithMaxFreq(10, @unigram)
            return Util.randomItem(max10)
        end
    end
    
    def buildRandSentance
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
                sentance = sentance.capitalize
        return sentance
    end
    
    def printStats
        maxW = ""
        maxCount = 0
        oneCount = 0

        n = Hash.new
        out = File.new("wordlist.csv", "w")
        maxN = 0
        @unigram.each_key do |word|
            lw = word
            if @unigram[lw] > maxCount
                maxW = lw;
                maxCount = @unigram[lw]
            end
            if @unigram[lw] == 1
                oneCount += 1
            end
            # count the counts
            if n.has_key?(@unigram[lw])
                n[@unigram[lw]] += 1;
            else
                n[@unigram[lw]] = 1;
            end
            out.puts("#{word},#{@unigram[word]}")
        end
        out.close

        out = File.new("trigram.csv", "w")
        @trigram.each_key do |w1|
            @trigram[w1].each_key do |w2|
                @trigram[w1][w2].each_key do |w3|
                    out.puts("#{w1} #{w2} #{w3}, #{@trigram[w1][w2][w3]}")
                end
            end
        end
        out.close

        puts "Found #{@uCount} words.";
        puts "The bigram has #{@bCount} phrases.";
        puts "The trigram has #{@tCount} phrases.";
        puts "The most common word was \"#{maxW}\" which appeared #{maxCount} times";
        puts "There were #{oneCount} words that only appeared once.";
    end
end
