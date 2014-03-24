require 'spec_helper'

describe VideosController do
  let(:video) { Fabricate(:video) }

  context "GET 'show'" do
    context "without signing in" do
      before(:each) do
        get "show", id: video.id
      end

      it "redirects to sign in page" do
        response.should redirect_to(sign_in_path)
      end

      it "will not set @video" do
        assigns(:video).should == nil
      end

      it "will not set @reviews" do
        assigns(:reveiws).should be_nil
      end
    end

    context "signed in" do
      before(:each) do
        session[:user_id] = Fabricate(:user)
        get "show", id: video.id
      end

      it "returns http success" do
        response.should be_success
      end

      it "sets @video" do
        assigns(:video).should == video
      end

      it "@review ordered by created_at DESC" do
        review_1 = Fabricate(:review, video: video, created_at: 2.day.ago)
        review_2 = Fabricate(:review, video: video, created_at: 1.day.ago)
        assigns(:reviews).should == [review_2, review_1]
      end
    end
  end

  context "GET 'search'" do
    context "not signed in" do
      before(:each) do
        get "search", q: video.title
      end

      it "redirects to sign in page" do
        response.should redirect_to(sign_in_path)
      end

      it "will not set @videos" do
        assigns(:videos).should == nil
      end
    end

    context "signing in" do
      before(:each) do
        session[:user_id] = Fabricate(:user).id
        get "search", q: video.title
      end

      it "returns http success" do
        response.should be_success
      end

      it "sets @videos" do
        assigns(:videos).should == [video]
      end
    end
  end

  context "POST 'add_to_my_queue'" do
    it "redirects to sign_in_path if not signed in" do
      post "add_to_my_queue"
      expect(response).to redirect_to(sign_in_path)
    end

    context "by an authenticated user" do
      let!(:user)   { Fabricate(:user) }
      let!(:video)  { Fabricate(:video) }
      let!(:review) { Fabricate(:review,     video: video, user: user, rating: 5) }

      before do

        session[:user_id] = user.id
      end

      it "creates a queue_item" do
        expect do
          post "add_to_my_queue", video_id: video.id
        end.to change{ QueueItem.count }.by(1)
      end

      it "creates a queue_item which is associated with the video" do
        post "add_to_my_queue", video_id: video.id
        queue_item = QueueItem.last
        expect(queue_item.video).to eq(video)
      end

      it "creates a queue_item which is associated with the user" do
        post "add_to_my_queue", video_id: video.id
        queue_item = QueueItem.last
        expect(queue_item.user).to eq(user)
      end

      it "creates a queue_item whill is appended to the user's queue" do
        Fabricate(:queue_item, user: user, video: Fabricate(:video), position: 3)
        Fabricate(:queue_item, user: user, video: Fabricate(:video), position: 2)

        post "add_to_my_queue", video_id: video.id
        queue_item = QueueItem.last
        expect(QueueItem.where(user: user).order("position ASC").last).to eq(queue_item)
      end

      it "redirects to my_queue page" do
        post "add_to_my_queue", video_id: video.id
        expect(response).to redirect_to(my_queue_path)
      end

      it "does not add new queue_item if it was already exists" do
        Fabricate(:queue_item, user: user, video: video)
        expect do
          post "add_to_my_queue", video_id: video.id
        end.not_to change{ QueueItem.count }
      end
    end
  end

end
