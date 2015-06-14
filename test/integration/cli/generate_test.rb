require 'test_helper'

describe 'lotus generate' do
  describe 'action' do
    let(:options)           { '' }
    let(:app_name)          { 'web' }
    let(:new_app_name)      { 'api' }
    let(:template_engine)   { 'erb' }
    let(:framework_testing) { 'minitest' }
    let(:klass)             { 'test' }

    def create_temporary_dir
      @tmp = Pathname.new(@pwd = Dir.pwd).join('tmp/integration/cli/generate')
      @tmp.rmtree if @tmp.exist?
      @tmp.mkpath

      Dir.chdir(@tmp)
    end

    def generate_application
      `bundle exec lotus new #{ @app_name = 'delivery' }#{ options }`
      Dir.chdir(@root = @tmp.join(@app_name))

      File.open(@root.join('.lotusrc'), 'w') do |f|
        f.write <<-LOTUSRC
architecture=container
test=#{ framework_testing }
template=#{ template_engine }
        LOTUSRC
      end
    end

    def generate_action
      `bundle exec lotus generate action #{ app_name } dashboard#index`
    end

    def generate_action_with_camlcase
      `bundle exec lotus generate action #{ app_name } AncientBooks#ToggleVisibility`
    end

    def generate_action_without_view
      `bundle exec lotus generate action #{ app_name } dashboard#foo --skip-view`
    end

    def generate_action_with_camlcase_without_view
      `bundle exec lotus generate action #{ app_name } DashBoard#TestCase --skip-view`
    end

    def generate_model
      `bundle exec lotus generate model #{ klass }`
    end

    def generate_container
      `bundle exec lotus generate app #{ new_app_name } #{ new_options }`
    end

    def chdir_to_root
      Dir.chdir(@pwd)
    end

    before do
      create_temporary_dir
      generate_application
      generate_action
      generate_action_without_view
    end

    def after
      chdir_to_root
    end

    describe 'when application generates new action' do
      describe 'when controllers, action name are Underscored names.' do
        it 'generates an action' do
          @root.join('apps/web/controllers/dashboard/index.rb').must_be      :exist?
          @root.join('apps/web/views/dashboard/index.rb').must_be            :exist?
          @root.join('apps/web/templates/dashboard/index.html.erb').must_be  :exist?
          @root.join('spec/web/controllers/dashboard/index_spec.rb').must_be :exist?
          @root.join('spec/web/views/dashboard/index_spec.rb').must_be       :exist?
        end

        it 'generates an action without view' do
          @root.join('apps/web/controllers/dashboard/foo.rb').must_be      :exist?
          @root.join('apps/web/views/dashboard/foo.rb').wont_be            :exist?
          @root.join('apps/web/templates/dashboard/foo.html.erb').wont_be  :exist?
          @root.join('spec/web/controllers/dashboard/foo_spec.rb').must_be :exist?
          @root.join('spec/web/views/dashboard/foo_spec.rb').wont_be       :exist?
        end
      end

      describe 'when controllers, action name are CamelCase names.' do
        before do
          generate_action_with_camlcase
          generate_action_with_camlcase_without_view
        end
        it 'generates an action' do
          @root.join('apps/web/controllers/ancient_books/toggle_visibility.rb').must_be      :exist?
          @root.join('apps/web/views/ancient_books/toggle_visibility.rb').must_be            :exist?
          @root.join('apps/web/templates/ancient_books/toggle_visibility.html.erb').must_be  :exist?
          @root.join('spec/web/controllers/ancient_books/toggle_visibility_spec.rb').must_be :exist?
          @root.join('spec/web/views/ancient_books/toggle_visibility_spec.rb').must_be       :exist?
        end

        it 'generates an action without view' do
          @root.join('apps/web/controllers/dash_board/test_case.rb').must_be      :exist?
          @root.join('apps/web/views/dash_board/test_case.rb').wont_be            :exist?
          @root.join('apps/web/templates/dash_board/test_case.html.erb').wont_be  :exist?
          @root.join('spec/web/controllers/dash_board/test_case_spec.rb').must_be :exist?
          @root.join('spec/web/views/dash_board/test_case_spec.rb').wont_be       :exist?
        end
      end
    end

    describe 'when application generates new model' do
      before do
        generate_model
      end
      describe 'when model names are Underscored names.' do
        it 'generates model' do
          @root.join('lib/delivery/entities/test.rb').must_be                      :exist?
          @root.join('lib/delivery/repositories/test_repository.rb').must_be       :exist?
          @root.join('spec/delivery/entities/test_spec.rb').must_be                :exist?
          @root.join('spec/delivery/repositories/test_repository_spec.rb').must_be :exist?
        end
      end

      describe 'when model names are CamelCase names.' do
        let(:klass) { 'TestCase' }

        it 'generates model' do
          @root.join('lib/delivery/entities/test_case.rb').must_be                      :exist?
          @root.join('lib/delivery/repositories/test_case_repository.rb').must_be       :exist?
          @root.join('spec/delivery/entities/test_case_spec.rb').must_be                :exist?
          @root.join('spec/delivery/repositories/test_case_repository_spec.rb').must_be :exist?
        end
      end
    end

    describe 'when application generates new container' do
      let(:new_options) { '' }

      before do
        generate_container
      end

      it 'generates new container' do
        @root.join('apps/api/application.rb').must_be                 :exist?
        @root.join('apps/api/config/routes.rb').must_be               :exist?
        @root.join('apps/api/views/application_layout.rb').must_be    :exist?
        @root.join('apps/api/templates/application.html.erb').must_be :exist?
      end

      it 'inserts configuration files' do
        content = @root.join('config/environment.rb').read
        content.must_match %(mount Api::Application, at: '/api')
        content.must_match %(require_relative '../apps/api/application')
        content = @root.join('.env.development').read
        content.must_match %(API_DATABASE_URL)
        content.must_match %(API_SESSIONS_SECRET)
        content = @root.join('.env.test').read
        content.must_match %(API_DATABASE_URL)
        content.must_match %(API_SESSIONS_SECRET)
      end

      describe 'with options application base url' do
        let(:new_options) { ' --application-base-url=/api_v1' }

        it 'inserts configuration files' do
          content = @root.join('config/environment.rb').read
          content.must_match %(mount Api::Application, at: '/api_v1')
        end
      end
    end

    describe 'when application is generated with minitest' do
      it 'generates action spec' do
        content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
        content.must_include %(must_equal)
      end

      it 'generates view spec' do
        content = @root.join('spec/web/views/dashboard/index_spec.rb').read
        content.must_include %(must_equal)
      end
    end

    describe 'when application is generated with rspec' do
      let(:framework_testing) { 'rspec' }

      it 'generates action spec' do
        content = @root.join('spec/web/controllers/dashboard/index_spec.rb').read
        content.must_include %(expect)
      end

      it 'generates view spec' do
        content = @root.join('spec/web/views/dashboard/index_spec.rb').read
        content.must_include %(expect)
      end
    end

    describe 'when application is generated with HAML' do
      let(:template_engine) { 'haml' }

      it 'generates HAML template' do
        @root.join('apps/web/templates/dashboard/index.html.haml').must_be :exist?
      end
    end

    describe 'with unknown application' do
      let(:app_name) { 'unknown' }

      it "doesn't generate the action" do
        @root.join('apps/unknown/controllers/dashboard/index.rb').wont_be      :exist?
        @root.join('apps/unknown/views/dashboard/index.rb').wont_be            :exist?
        @root.join('apps/unknown/templates/dashboard/index.html.erb').wont_be  :exist?
        @root.join('spec/unknown/controllers/dashboard/index_spec.rb').wont_be :exist?
        @root.join('spec/unknown/views/dashboard/index_spec.rb').wont_be       :exist?
      end
    end
  end
end
