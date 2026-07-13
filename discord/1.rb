require "json"

file = File.open("servants_orig_dont_change.json").read

file = JSON.parse(file)
out = {}

rannge = [ 'Радиус', 'радиус', 'ренж' ]
counter=0
for message in file["messages"]
  content = message["content"]
  nn=0

  if content.lines.first.to_s.include?("S-") || content.lines.first.to_s.include?("s-") || content.lines.first.to_s.include?("s-")

    out[content.lines.first.chomp]=counter*100
    counter+=1
  else
    # p content.lines.first
    if content.lines.first==nil
      p content
    end
    next
  end
end
p out.size()
File.write("out.json", out.to_json)
