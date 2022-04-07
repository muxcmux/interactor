module Interactor
  describe Organizer do
    include_examples :lint

    let(:organizer) { Class.new.send(:include, Organizer) }

    describe ".organize" do
      let(:interactor2) { double(:interactor2) }
      let(:interactor3) { double(:interactor3) }
      let(:interactor4) { double(:interactor4) }
      let(:interactor5) { double(:interactor5) }

      it "sets interactors given class arguments" do
        expect {
          organizer.organize(interactor2, interactor3)
        }.to change {
          organizer.organized
        }.from([]).to([{
          interactors: [interactor2, interactor3],
          options: {}
        }])
      end

      it "sets interactors given an array of classes" do
        expect {
          organizer.organize([interactor2, interactor3])
        }.to change {
          organizer.organized
        }.from([]).to([{
          interactors: [interactor2, interactor3],
          options: {}
        }])
      end

      it "sets a group for each call to organize" do
        expect {
          organizer.organize interactor2
          organizer.organize interactor3
          organizer.organize interactor4, interactor5, if: :condition
        }.to change {
          organizer.organized
        }.from([]).to([{
          interactors: [interactor2],
          options: {}
        }, {
          interactors: [interactor3],
          options: {}
        }, {
          interactors: [interactor4, interactor5],
          options: { if: :condition }
        }])
      end
    end

    describe ".organized" do
      it "is empty by default" do
        expect(organizer.organized).to eq([])
      end
    end

    describe "#call" do
      let(:instance) { organizer.new }
      let(:context) { double(:context) }
      let(:interactor2) { double(:interactor2) }
      let(:interactor3) { double(:interactor3) }
      let(:interactor4) { double(:interactor4) }
      let(:interactor_instance2) { double(:interactor_instance2) }
      let(:interactor_instance3) { double(:interactor_instance3) }
      let(:interactor_instance4) { double(:interactor_instance4) }
      let(:organized) do
        [
          {
            interactors: [interactor2, interactor3, interactor4],
            options: {}
          }
        ]
      end

      before do
        allow(interactor2).to receive(:new) { interactor_instance2 }
        allow(interactor3).to receive(:new) { interactor_instance3 }
        allow(interactor4).to receive(:new) { interactor_instance4 }
        allow(instance).to receive(:context) { context }
        allow(organizer).to receive(:organized) { organized }
      end

      it "calls each interactor in order with the context" do
        expect(interactor2).to receive(:new).once.with(context).ordered
        expect(interactor_instance2).to receive(:run!).once.ordered
        expect(interactor3).to receive(:new).once.with(context).ordered
        expect(interactor_instance3).to receive(:run!).once.ordered
        expect(interactor4).to receive(:new).once.with(context).ordered
        expect(interactor_instance4).to receive(:run!).once.ordered
        instance.call
      end

      context "with if option" do
        let(:organized) do
          [
            {
              interactors: [interactor2],
              options: { if: proc { false } }
            }, {
              interactors: [interactor3, interactor4],
              options: { if: proc { true } }
            }
          ]
        end

        it "calls each interactor in order with the context, skipping the group with false if option" do
          expect(interactor2).to_not receive(:new).with(context)
          expect(interactor_instance2).to_not receive(:run!)
          expect(interactor3).to receive(:new).once.with(context).ordered
          expect(interactor_instance3).to receive(:run!).once.ordered
          expect(interactor4).to receive(:new).once.with(context).ordered
          expect(interactor_instance4).to receive(:run!).once.ordered
          instance.call
        end
      end
    end
  end
end
