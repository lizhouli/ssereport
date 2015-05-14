require 'nokogiri'
require 'open-uri'
require 'pdf/reader'

class Ssereport
    def initialize(filename)
        @file = filename
        @ids = []
    end

    def read_from_file
        idfile = File.open(@file, "r")
        today = Time.now
        # idfile.each { |line| @ids << ("http://static.sse.com.cn/disclosure/listedinfo/announcement/c/#{today.strftime("%Y-%m-%d")}/#{line.chomp}.pdf").chomp }
        idfile.each { |line| @ids << ("http://static.sse.com.cn/disclosure/listedinfo/announcement/c/2015-04-29/#{line.chomp}.pdf").chomp }
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

    def open_report
        @ids.each do |link|
            if link_available?(link)
                doc = open(link)
                reader = PDF::Reader.new(doc)
                puts reader.info
                outfile = File.open("out.txt", "w+")
                #reader.pages.each do |page|
                    page = reader.page(1)
                    outfile.write page.text
                #end
            else
                puts "ERROR: #{link} is not available"
            end
        end
    end

    def test
        puts "size = #{@ids.size()}"
        puts @ids 
        puts link_available?(@ids[0]) ? "true" : "false"
    end
end


report = Ssereport.new("stock.txt")
report.read_from_file
report.open_report
#report.test
