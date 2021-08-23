require "../src/gphoto2"

# List all configuration values in tree form.

def visit(widget, level = 0)
  indent = "  " * level

  puts "#{indent}#{widget.name.colorize(:green)}#{" (read-only)".colorize(:cyan) if widget.readonly?}"

  if widget.type.window? || widget.type.section?
    widget.children.each { |child| visit(child, level + 1) }
    return
  end

  indent += "  "

  puts "#{indent}label: #{widget.label.colorize(:yellow)}"
  puts "#{indent}info: #{widget.info.colorize(:yellow)}" if widget.info.presence
  puts "#{indent}type: #{widget.type.colorize(:magenta)}"
  puts "#{indent}value: #{widget.value.try(&.colorize(:blue)) || "<nil>".colorize(:red)}"

  case widget
  when GPhoto2::CameraWidget::Range
    range = widget.range
    step = (range.size > 1) ? range[1] - range[0] : 1.0
    puts "#{indent}range: #{range.first..range.last}/#{step}"
  when GPhoto2::CameraWidget::Radio
    puts "#{indent}options: #{widget.choices.inspect.colorize(:dark_gray)}"
  end
end

GPhoto2::Camera.first do |camera|
  visit(camera.window)
end
