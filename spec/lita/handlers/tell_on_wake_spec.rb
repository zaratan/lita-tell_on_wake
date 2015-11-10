require "spec_helper"

def mod
  Lita::Handlers::TellOnWake.new("")
end

def redis
  mod.redis
end

def redis_list(key)
  Redis::List.new(key, redis, marshal: true)
end

describe Lita::Handlers::TellOnWake, lita_handler: true do
  let(:sender) {Lita::User.create("1234", name: "Skizzk")}
  let(:user) {Lita::User.create("1235", name: "Zaratan")}
  let(:now) {Time.now}

  before do
    allow(Time).to receive(:now).and_return(now)
  end

  it { is_expected.to route_command("tell zaratan il love apple").to(:store_tell) }
  it { is_expected.to route_event(:user_joined_room).to(:send_tell) }
  it { is_expected.to route("anything").to(:send_tell) }

  subject do
    send_command("tell #{user.name} I love you", as: sender)
  end

  it "stores tell messages for later" do
    subject
    expect(redis_list(user.name).first).to eq({message: "I love you", user: sender.name, time: now.to_s})
  end

  it "stores message on unexisting user" do
    send_command("tell blu youpi", as: sender)
    expect(redis_list("blu")).not_to be_empty
  end

  it "responds a succesfull message" do
    expect{subject}.to change{replies}.to([mod.t("success_enqueue", user_name: user.name)])
  end

  context "when a user act" do
    subject do
      send_message("anything", as: user)
    end

    context "a tell message for that user is stored" do
      before do
        redis_list(user.name) << {message: "message 1", user: sender.name, time: now.to_s}
      end

      it "sends privately this message for that user" do
        expect{subject}.to change{replies}.to([mod.t("tell", message: "message 1", user: sender.name, time: now.to_s)])
      end
    end

    context "more than one message is stored" do
      before do
        redis_list(user.name) << {message: "message 1", user: sender.name, time: now.to_s}
        redis_list(user.name) << {message: "message 2", user: sender.name, time: now.to_s}
      end

      it "sends them in the right order" do
        expect{subject}.to change{replies.first}.to(mod.t("tell", message: "message 1", user: sender.name, time: now.to_s))
        expect(redis_list(user.name)).to be_empty
      end
    end

    context "no tell message is stored" do
      before do
        redis_list("NOT_THIS_USER") << {message: "message 1", user: sender.name, time: now.to_s}
      end

      it "doesn't do anything" do
        expect{subject}.not_to change{replies}
        expect(redis_list("NOT_THIS_USER")).not_to be_empty
      end
    end
  end
end
