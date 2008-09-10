module Clearance 
  module TestHelper
    
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods
      def login_as(user = nil)
        user ||= Factory(:user)
        @request.session[:user_id] = user.id
        return user
      end

      def logout 
        @request.session[:user_id] = nil
      end
    end
    
    module ClassMethods
      def should_deny_access_on(command, opts = {})
        opts[:redirect] ||= "root_url"

        context "on #{command}" do
          setup { eval command }
          should_redirect_to opts[:redirect]
          if opts[:flash]
            should_set_the_flash_to opts[:flash]
          else
            should_not_set_the_flash
          end
        end
      end
      
      def should_filter(*keys)
        keys.each do |key|
          should "filter #{key}" do
            assert @controller.respond_to?(:filter_parameters),
              "The key #{key} is not filtered"
            filtered = @controller.send(:filter_parameters, {key.to_s => key.to_s})
            assert_equal '[FILTERED]', filtered[key.to_s],
              "The key #{key} is not filtered"
          end
        end
      end
      
      def should_have_user_form
        should "have the user form" do
          assert_select "form" do
            assert_select "input[type=text][name=?]", "user[email]"
            %w(password password_confirmation).each do |field|
              assert_select "input[type=password][name=?]", "user[#{field}]"
            end
          end
        end
      end

      def logged_in_user_context(&blk)
        context "When logged in as a user" do
          setup do
            @user = Factory :user
            login_as @user
          end
          merge_block(&blk)
        end
      end
    end
  
  end
end
