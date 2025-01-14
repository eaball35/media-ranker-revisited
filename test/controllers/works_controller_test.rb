require "test_helper"

describe WorksController do
  before do
    perform_login(users(:dan))
  end

  let(:existing_work) { works(:album) }

  describe "root" do
    describe 'logged out' do
      it 'succeeds if user is not logged in' do
        delete logout_path
        expect(session[:user_id]).must_be_nil
        
        get root_path

        must_respond_with :success
      end
    end

    describe 'logged in' do
      it "succeeds with all media types" do
        get root_path

        must_respond_with :success
      end

      it "succeeds with one media type absent" do
        only_book = works(:poodr)
        only_book.destroy

        get root_path

        must_respond_with :success
      end

      it "succeeds with no media" do
        Work.all do |work|
          work.destroy
        end

        get root_path

        must_respond_with :success
      end
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    describe 'logged out' do
      it 'responds with redirect and error message if not logged in' do
        delete logout_path
        expect(session[:user_id]).must_be_nil
        
        get works_path

        assert_equal :failure, flash[:status]
        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end
    end
    
    describe 'logged in' do
      it "succeeds when there are works" do
        perform_login(users(:dan))
        
        get works_path

        must_respond_with :success
      end

      it "succeeds when there are no works" do
        Work.all do |work|
          work.destroy
        end

        get works_path

        must_respond_with :success
      end
    end
  end

  describe "new" do
    describe 'logged out' do
      it 'responds with redirect and error message if not logged in' do
        delete logout_path
        expect(session[:user_id]).must_be_nil
        
        get new_work_path

        assert_equal :failure, flash[:status]
        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end
    end
    
    describe 'logged in' do
      it "succeeds" do
        get new_work_path

        must_respond_with :success
      end
    end
  end

  describe "create" do
    describe 'logged out' do
      it 'responds with redirect and error message if not logged in' do
        delete logout_path
        expect(session[:user_id]).must_be_nil
        
        new_work = { work: { title: "Dirty Computer", category: "album" } }
        post works_path, params: new_work

        assert_equal :failure, flash[:status]
        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end
    end

    describe 'logged in' do
      it "creates a work with valid data for a real category" do
        new_work = { work: { title: "Dirty Computer", category: "album" } }

        expect {
          post works_path, params: new_work
        }.must_change "Work.count", 1

        new_work_id = Work.find_by(title: "Dirty Computer").id

        must_respond_with :redirect
        must_redirect_to work_path(new_work_id)
      end

      it "renders bad_request and does not update the DB for bogus data" do
        bad_work = { work: { title: nil, category: "book" } }

        expect {
          post works_path, params: bad_work
        }.wont_change "Work.count"

        must_respond_with :bad_request
      end

      it "renders 400 bad_request for bogus categories" do
        INVALID_CATEGORIES.each do |category|
          invalid_work = { work: { title: "Invalid Work", category: category } }

          proc { post works_path, params: invalid_work }.wont_change "Work.count"

          Work.find_by(title: "Invalid Work", category: category).must_be_nil
          must_respond_with :bad_request
        end
      end
    end
  end

  describe "show" do
    describe 'logged out' do
      it 'responds with redirect and error message if not logged in' do
        delete logout_path
        expect(session[:user_id]).must_be_nil
        
        get work_path(existing_work.id)

        assert_equal :failure, flash[:status]
        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end
    end
    
    describe 'logged in' do
      it "succeeds for an extant work ID" do
        get work_path(existing_work.id)

        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        destroyed_id = existing_work.id
        existing_work.destroy

        get work_path(destroyed_id)

        must_respond_with :not_found
      end
    end
  end

  describe "edit" do
    describe 'logged out' do
      it 'responds with redirect and error message if not logged in' do
        delete logout_path
        expect(session[:user_id]).must_be_nil
        
        get edit_work_path(existing_work.id)

        assert_equal :failure, flash[:status]
        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end
    end

    describe 'logged in' do
      it "succeeds for an existing work ID" do
        get edit_work_path(existing_work.id)
  
        must_respond_with :success
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_id = existing_work.id
        existing_work.destroy

        get edit_work_path(bogus_id)

        must_respond_with :not_found
      end
    end
  end

  describe "update" do
    describe 'logged out' do
      it 'responds with redirect and error message if not logged in' do
        delete logout_path
        expect(session[:user_id]).must_be_nil
        
        updates = { work: { title: "Dirty Computer" } }
        put work_path(existing_work), params: updates

        assert_equal :failure, flash[:status]
        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end
    end

    describe 'logged in' do
      it "redirects and throws error message for an existing work ID which doesn't belong to user" do
        work = works(:poodr)
        updates = { work: { title: "Dirty Computer" } }
        put work_path(work), params: updates
        
        assert_equal :failure, flash[:status]
        assert_equal "You can't update a work you don't own.", flash[:result_text]
        must_redirect_to work_path(work)
      end

      it "succeeds for valid data and an extant work ID" do
        updates = { work: { title: "Dirty Computer" } }

        expect {
          put work_path(existing_work), params: updates
        }.wont_change "Work.count"
        updated_work = Work.find_by(id: existing_work.id)

        updated_work.title.must_equal "Dirty Computer"
        must_respond_with :redirect
        must_redirect_to work_path(existing_work.id)
      end

      it "renders bad_request for bogus data" do
        updates = { work: { title: nil, category: '' } }

        expect {
          put work_path(existing_work), params: updates
        }.wont_change "Work.count"

        work = Work.find_by(id: existing_work.id)

        must_respond_with :not_found
      end

      it "renders 404 not_found for a bogus work ID" do
        bogus_id = existing_work.id
        existing_work.destroy

        put work_path(bogus_id), params: { work: { title: "Test Title" } }

        must_respond_with :not_found
      end
    end
  end

  describe "destroy" do
    describe 'logged out' do
      it 'responds with redirect and error message if not logged in' do
        delete logout_path
        expect(session[:user_id]).must_be_nil
        
        delete work_path(existing_work.id)

        assert_equal :failure, flash[:status]
        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end
    end

    describe 'logged in' do
      it "redirects and throws error message for an existing work ID which doesn't belong to user" do
        work = works(:poodr)
        expect {
          delete work_path(work.id)
        }.wont_change "Work.count"

        assert_equal :failure, flash[:status]
        assert_equal "You can't delete a work you don't own.", flash[:result_text]
        must_redirect_to work_path(work.id)
      end
      
      it "succeeds for an extant work ID" do
        expect {
          delete work_path(existing_work.id)
        }.must_change "Work.count", -1

        must_respond_with :redirect
        must_redirect_to root_path
      end

      it "renders 404 not_found and does not update the DB for a bogus work ID" do
        bogus_id = existing_work.id
        existing_work.destroy

        expect {
          delete work_path(bogus_id)
        }.wont_change "Work.count"

        must_respond_with :not_found
      end
    end
  end

  describe "upvote" do
    before do
      delete logout_path
    end

    describe 'logged out' do
      it "redirects to the root page if no user logged in" do
        perform_login(User.new)
        expect(session[:user_id]).must_be_nil

        expect {
          post upvote_path(existing_work.id)
        }.wont_change "Vote.count"
        
        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end

      it "redirects to the root page after the user has logged out" do
        user = users(:kari)
        perform_login(user)
        expect(session[:user_id]).wont_be_nil
        delete logout_path
        expect(session[:user_id]).must_be_nil

        expect {
          post upvote_path(existing_work.id)
        }.wont_change "Vote.count"

        assert_equal "You must be logged in to do that.", flash[:result_text]
        must_redirect_to root_path
      end
    end

    describe 'logged in' do
      it 'redirects and displays error if voting on your own work' do
        user = users(:dan)
        dan_work = works(:album)
        perform_login(user)

        expect {
          post upvote_path(dan_work.id)
        }.wont_change "Vote.count"


        assert_equal :failure, flash[:status]
        assert_equal "You can't upvote your own work.", flash[:result_text]
        must_redirect_to work_path(dan_work.id)
      end

      it "succeeds for a logged-in user and a fresh user-vote pair" do
        work = works(:another_album)
        user = users(:kari)
        perform_login(user)
        expect(session[:user_id]).wont_be_nil

        vote = Vote.find_by(work_id: work.id, user_id: user.id)
        expect(vote).must_be_nil

        expect {
          post upvote_path(work.id)
        }.must_change "Vote.count", 1

        assert_equal :success, flash[:status]
        assert_equal "Successfully upvoted!", flash[:result_text]
        must_redirect_to work_path(work.id)
      end

      it "redirects to the work page if the user has already voted for that work" do
        user = users(:dan)
        perform_login(user)
        expect(session[:user_id]).wont_be_nil
        
        vote = Vote.find_by(work_id: existing_work.id, user_id: user.id)
        expect(vote).wont_be_nil

        expect {
          post upvote_path(existing_work.id)
        }.wont_change "Vote.count"

        assert_equal :failure, flash[:status]
        must_redirect_to work_path(existing_work.id)
      end
    end
  end
end
