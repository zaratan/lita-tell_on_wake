module Lita
  module Handlers
    class TellOnWake < Handler
      attr_accessor :response

      route(//, :send_tell)
      on(:user_joined_room, :send_tell)

      def send_tell(r)
        @response = r
        @user_name = r.user.name
        user_list.each do |tell|
          r.reply_privately(t("tell", message: tell[:message], user: tell[:user], time: tell[:time]))
        end
        user_list.clear
      end

      route(/^tell\s+(?<user>\S+)\s+(?<message>\S.*)/, :store_tell, command: true, help:{
        "tell somebody something" => "Tell something to somebody as soon as he acts again"
      })
      
      def store_tell(r)
        @response = r
        @user_name = r.match_data[:user]
        add_to_user_list(@user_name, r.match_data[:message])
        r.reply(t("success_enqueue", user_name: @user_name))
      end

      def user_list(name=nil)
        name = name.downcase if name
        Redis::List.new(name || user_find.name.downcase, redis, marshal: true)
      end

      def add_to_user_list(name, message)
        user_list(name) << {message: message, user: response.user.name, time: Time.now.to_s}
      end

      def user_find
        @user_find ||= User.fuzzy_find(@user_name)
      end

      Lita.register_handler(self)
    end
  end
end
