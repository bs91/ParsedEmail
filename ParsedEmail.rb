#!/usr/bin/env ruby

class ParsedEmail
  attr_accessor :headers, :body, :content

  def initialize(file)
    @headers = {}
    @body = Body.new
    @content = ""
    EmailParser.new(self, file)
  end

  private
  class Section
    attr_accessor :headers, :content

    def initialize(headers = {}, content = "")
      @headers = headers
      @content = content
    end
  end

  class Boundary
    attr_accessor :id, :sections
    
    def initialize(id, sections = [])
      @id = id
      @sections = sections
    end

    def getLastSection
      @sections[@sections.length-1]
    end
  end

  class Body
    attr_accessor :boundaries

    def initialize(boundaries = [])
      @boundaries = boundaries
    end

    def getLastBoundary
      @boundaries[@boundaries.length-1]
    end
  end

  class EmailParser
    attr_accessor :file

    def initialize(email, file)
      @file = File.open(file, "r").each_char
      @cur_char = ""
      @email = email
      self.header
    end

    def endOfFile?
      begin
        @file.peek
        false
      rescue StopIteration
        #catching the exception here will let us know the file has reached an end.
        true
      end
    end

    def getNextLine(delim)
      temp = ""
      until @cur_char == delim
        temp << @cur_char
        @cur_char = @file.next
      end
      temp
    end

    def section
      sectionVal = ""
      temp = ""
      boundaryID = @email.body.getLastBoundary.id

      if @file.peek == "\n" || @file.peek == "-"
        @cur_char = @file.next
        temp = getNextLine("\n")
      end
      if temp == "--#{boundaryID}--"
        if @file.peek
          @cur_char = @file.next
          boundary(true)
        end
      else
        section = Section.new
        @email.body.getLastBoundary.sections.concat([section])
        @cur_char = @file.next
        header(true)
        if !endOfFile?
          section()
        end
      end
    end

    def stripString(oString, dval)
      if @email.body.boundaries.length == 0
        @email.headers[:"Content-Type"] = oString[0..(oString.index(dval)-1)]
      else
        @email.body.getLastBoundary.getLastSection.headers[:"Content-Type"] = oString[0..(oString.index(dval)-1)]
      end
      oString
    end

    def getString(oString, dval)
      temp = oString[oString.index(dval)..oString.length]
      temp["boundary=\""] = ""
      temp ["\""] = ""
      stripString(oString, dval)
      boundary = Boundary.new(temp)
      @email.body.boundaries.concat([boundary])
      temp
    end

    def boundary
      sectionVal = ""
      num = @email.body.boundaries.length
      if num == 0
        dataKey = @email.headers[:"Content-Type"][0]
      else
        dataKey = @email.body.getLastBoundary.getLastSection.headers[:"Content-Type"][0]
      end
      dataVal = "boundary"
      temp = ""
      if dataKey.include? dataVal
        temp = getString(dataKey, dataVal)
        section
      end
      temp
    end

    def getContent
      content = ""
      boundaryID = @email.body.getLastBoundary.id
      cur_line = getNextLine("\n")
      until cur_line.gsub(/\s/, "") == "--#{boundaryID}" || cur_line.gsub(/\s/, "") == "--#{boundaryID}--" || endOfFile?
        content << cur_line
        if cur_line.length == 0
          @cur_char = @file.next
        end
        cur_line = getNextLine("\n")
      end
      content
    end

    def body(skip, multi = false)
      if skip
        @cur_char = @file.next
        bodyVal = ""
        key = boundary
        bodyVal = getContent
        if @email.body.boundaries.length > 0 && bodyVal != ""
          @email.body.getLastBoundary.getLastSection.content = bodyVal
        else
          @email.content = bodyVal
        end
      else
        @cur_char = @file.next
        if multi
          header(true)
        else
          header
        end
      end
    end

    def field
      getNextLine(":")
    end

    def value
      if @file.peek =~ /[ \t]/
        @cur_char = @file.next
      end

      value = getNextLine("\n")
      value = value.gsub(/^\s+|\s+$/, "")
      value
    end

    def header(multi=false)
      key = ""
      val = ""
      returnVal = ""
      key = field
      @cur_char = @file.next
      val = value
      val << value while @file.peek =~ /[ \t]/
      if multi
        @email.body.getLastBoundary.getLastSection.headers.merge!({ key.to_sym =>[val.strip] }) { |key, v1, v2| [v1].concat([v2]) }
      else
        @email.headers.merge!(returnVal = { key.to_sym => [val.strip] }) { |key, v1, v2| [v1].concat([v2]) }
      end
      body(@file.peek == "\n", multi)
    end
  end
end

# HOW TO USE eData = ParsedEmail.new("testEmail")
