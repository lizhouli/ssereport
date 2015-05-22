require 'nokogiri'
require 'open-uri'
require 'pdf/reader'
require_relative 'finance_data'

class Ssereport
    attr_accessor :finance
    include FData
    def initialize(filename)
        # from module FData
        @finance = [] 
        
        @ids = []
        idfile = File.open(filename, "r")
        today = Time.now
        # idfile.each { |line| @ids << ("http://static.sse.com.cn/disclosure/listedinfo/announcement/c/#{today.strftime("%Y-%m-%d")}/#{line.chomp}.pdf").chomp }
        idfile.each { |line| @ids << ("http://static.sse.com.cn/disclosure/listedinfo/announcement/c/2015-04-29/#{line.chomp}.pdf").chomp }
        
        @ids.each do |link|
            if link_available?(link)
                doc = open(link)
                @reader = PDF::Reader.new(doc)
                puts @reader.info
            else
                puts "ERROR: #{link} is not available"
            end
        end
    end

    def link_available?(link)
        begin
            doc = open(link)
            response = doc
        rescue OpenURI::HTTPError => e
            response = e.io
        end
        response.status[0].to_i == 200
    end

    def extract_two_value?(str)
        return [false, 0, 0] unless str.strip.size() > 0
        nums = str.split
        return [false, 0, 0] unless nums.size() > 1
        if nums[0].to_f.to_s != nums[0]
            if nums[0] =~ /^-?\d+(,\d{3})+$/  || !nums[0].include?(",")
                nums[0].delete! ","
            else
                #puts "----------------------not matched: #{nums[0]}"
                nums_parts = nums[0].split(',')
                nums[0].clear
                nums[1].clear
                now_is_word1 = true
                nums_parts.each do |word|
                    if word.size() <= 3 && now_is_word1
                        nums[0] << word
                    elsif word.size() == 3 && !now_is_word1
                        nums[1] << word
                    else
                        nums[0] << word[0..2]
                        nums[1] << word[3..-1]
                        now_is_word1 = false
                    end
                end
                return [true, nums[0].to_f, nums[1].to_f]
            end
        end

        if nums[1].to_f.to_s != nums[1]
            if nums[1] =~ /^-?\d+(,\d{3})+$/  || !nums[1].include?(",")
                nums[1].delete! ","
            end
        end
        return [true, nums[0].to_f, nums[1].to_f]
    end

    def get_data
        outfile = File.open("finance.txt", "w+")
        copyarray = Array.new(FData::FINANCE_CONSTANT)
        @reader.pages.each do |page|
            content = page.text
            found = false
            mapid = 0
            content.each_line do |line|
                if !found
                    copyarray.each do |constant|
                        if line.include? constant
                            found = true
                            mapid = FData::FINANCE_MAP[constant]
                            copyarray.delete(constant)
                            break
                        end
                    end
                end
                # if the key line is detected, check this line to get the finance data first,  
                # if this line doesn't contain the data because the data is too long, scan the next line
                if found
                    # English ) and Chinese ） !!!!
                    current = line.sub(/.*[\)\）]/, '').lstrip
                    # read next line if there is no number in this line
                    values = extract_two_value?(current)
                    if !values[0]
                        next
                    end
                    found = false
                    @finance[mapid] = values[1..2]
                end
            end
            #outfile.write page.text
            break
        end
        @finance.each_index do |index|
            outfile.write FData::FINANCE_COMP_CONSTANT[index]
            outfile.write "[本报告期末, 上年度期末]: #{@finance[index]}\n"
        end
    end

    def test
        puts "size = #{@ids.size()}"
        puts @ids 
        puts link_available?(@ids[0]) ? "true" : "false"
    end
end


report = Ssereport.new("stock.txt")
report.get_data
#report.test
