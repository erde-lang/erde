local x = (y, x) -> y + 4

const t = {
  hello: 'world',
};

hello!iterate(function(k, v)
  print("hello world")
end);

hello!iterate((k, v) -> k + v)

for k, v in ipairs(k) do
  print("hello")
end

if nil then
  print("hello")
end
