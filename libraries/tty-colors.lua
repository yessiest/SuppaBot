local color_names = {
  red = "0;31",
  green = "0;32",
  brown = "0;33",
  orange = "0;33",
  blue = "0;34",
  purple = "0;35",
  cyan = "0;36",
  yellow = "1;33",
  white = "1;37",
  blink = "5",
  bold = "1",
  italic = "3",
  underline = "4",
  inverse = "7",
  strikethrough = "9"
}
color_names["light red"] = "1;31"
color_names["light green"] = "1;32"
color_names["light blue"] = "1;34"
color_names["light purple"] = "1;35"
color_names["light cyan"] = "1;36"
color_names["light gray"] = "0;37"
--i do believe the vt100 color modifier system can be pronounced an official mug moment
return function(text,color_name)
  local effect = "\27[0m"
  local new_text = ""
  if color_names[color_name:lower()] then
    effect = "\27["..color_names[color_name:lower()].."m"
  end
  new_text = effect..text.."\27[0m"
  return new_text
end
