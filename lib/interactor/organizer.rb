module Interactor
  # Public: Interactor::Organizer methods. Because Interactor::Organizer is a
  # module, custom Interactor::Organizer classes should include
  # Interactor::Organizer rather than inherit from it.
  #
  # Examples
  #
  #   class MyOrganizer
  #     include Interactor::Organizer
  #
  #     organizer InteractorOne, InteractorTwo
  #   end
  module Organizer
    # Internal: Install Interactor::Organizer's behavior in the given class.
    def self.included(base)
      base.class_eval do
        include Interactor

        extend ClassMethods
        include InstanceMethods
      end
    end

    # Internal: Interactor::Organizer class methods.
    module ClassMethods
      # Public: Declare Interactors to be invoked as part of the
      # Interactor::Organizer's invocation. These interactors are invoked in
      # the order in which they are declared.
      #
      # interactors - Zero or more (or an Array of) Interactor classes.
      #
      # Examples
      #
      #   class MyFirstOrganizer
      #     include Interactor::Organizer
      #
      #     organize InteractorOne, InteractorTwo
      #   end
      #
      #   class MySecondOrganizer
      #     include Interactor::Organizer
      #
      #     organize [InteractorThree, InteractorFour]
      #   end
      #
      # Returns nothing.
      def organize(*interactors, **options)
        organized << {
          interactors: interactors.flatten,
          options: options || {}
        }
      end

      # Internal: An Array of declared Interactors with options to be invoked.
      #
      # Examples
      #
      #   class MyOrganizer
      #     include Interactor::Organizer
      #
      #     organize InteractorOne, InteractorTwo
      #     organize ConditionalInteractor, if: -> { true }
      #   end
      #
      #   MyOrganizer.organized
      #   # => [InteractorOne, InteractorTwo]
      #
      # Returns an Array of Interactor classes with options or an empty Array.
      def organized
        @organized ||= []
      end
    end

    # Internal: Interactor::Organizer instance methods.
    module InstanceMethods
      # Internal: Invoke the organized Interactors. An Interactor::Organizer is
      # expected not to define its own "#call" method in favor of this default
      # implementation.
      #
      # Returns nothing.
      def call
        self.class.organized.each do |organized|
          run_organized(organized[:interactors], organized[:options])
        end
      end

      def run_organized(interactors, options = {})
        run = if options[:if]
                options[:if].is_a?(Symbol) ? send(options[:if]) : instance_eval(&options[:if])
              else
                true
              end
        return unless run

        interactors.each do |interactor|
          i = interactor.new(context)
          i.run!
        rescue Failure
          i.send :run_on_failure_hooks
          raise
        end
      end
    end
  end
end
