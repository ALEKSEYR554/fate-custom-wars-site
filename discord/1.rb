require "json"

file = File.open("servants_orig_dont_change.json").read

file = JSON.parse(file)
out = {}

rannge = [ 'Радиус', 'радиус', 'ренж' ]

for message in file["messages"]
  content = message["content"]
  nn=0
  for line in content.lines
    break if nn>=10
    out[content[0..6].chomp]=0 if rannge.any? { |s| line.include? s }
    nn+=1
  end
end

File.write("out.json", out.to_json)
