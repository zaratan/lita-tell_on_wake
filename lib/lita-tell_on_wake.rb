require "lita"
require "redis-objects"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita/handlers/tell_on_wake"

Lita::Handlers::TellOnWake.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
