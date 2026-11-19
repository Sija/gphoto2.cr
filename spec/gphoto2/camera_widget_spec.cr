require "../spec_helper"

module GPhoto2
  describe CameraWidget do
    describe ".factory" do
      it "builds widget of a matching class" do
        {% for type in %w(Window Section Text Range Toggle Radio Menu Button Date) %}
          build_widget(:{{ type.downcase.id }}).should be_a CameraWidget::{{ type.id }}
        {% end %}
      end
    end

    describe CameraWidget::Base do
      it "exposes basic attributes" do
        widget = build_widget(:text, "foo")
        widget.name.should eq "foo"
        widget.label.should eq "foo"
        widget.type.text?.should be_true
        widget.readonly?.should be_false
        widget.parent.should be_nil
      end

      it "casts to subclasses" do
        widget = build_widget(:radio)
        widget.as_radio.should be widget
        widget.as_radio?.should be widget
        widget.as_text?.should be widget
        widget.as_toggle?.should be_nil
        expect_raises(TypeCastError) { widget.as_toggle }
      end

      describe "#value" do
        it "returns nil for empty values" do
          widget = build_widget(:text)
          widget.value = ""
          widget.value.should be_nil
          widget.value = "None"
          widget.value.should be_nil
        end
      end

      describe "#value?" do
        it "returns nil for widgets without value" do
          build_widget(:window).value?.should be_nil
          build_widget(:section).value?.should be_nil
          build_widget(:button).value?.should be_nil
        end
      end

      describe "#==" do
        it "compares value with any object using #to_s" do
          widget = build_widget(:text)
          widget.value = "400"
          (widget == 400).should be_true
          (widget == "400").should be_true
          (widget == 200).should be_false
        end

        it "compares value with symbol" do
          widget = build_widget(:text)
          widget.value = "Automatic"
          (widget == :automatic).should be_true
        end
      end

      describe "#in?" do
        it "checks against collections" do
          widget = build_widget(:text)
          widget.value = "Manual"
          widget.in?(%w(Manual Bulb)).should be_true
          widget.in?(%w(Auto)).should be_false
        end
      end

      describe "#flatten" do
        it "returns a flat hash of leaf widgets" do
          window = build_widget(:window, "main")
          section = build_widget(:section, "settings")
          text = build_widget(:text, "owner")
          GPhoto2.check! LibGPhoto2.gp_widget_append(section, text)
          GPhoto2.check! LibGPhoto2.gp_widget_append(window, section)

          flat = window.flatten
          flat.keys.should eq ["owner"]
          flat["owner"].parent.try(&.name).should eq "settings"
        end
      end
    end

    describe CameraWidget::Text do
      it "accepts strings, symbols and numbers" do
        widget = build_widget(:text).as_text
        widget.value = "foo"
        widget.value.should eq "foo"
        widget.value = :bar
        widget.value.should eq "Bar"
        widget.value = 1.5
        widget.value.should eq "1.5"
      end

      it "rejects other types" do
        expect_raises(ArgumentError) do
          build_widget(:text).value = [1]
        end
      end
    end

    describe CameraWidget::Toggle do
      it "accepts ints, bools and strings" do
        widget = build_widget(:toggle)
        widget.value = true
        widget.value.should eq 1
        widget.value = 0
        widget.value.should eq 0
        widget.value = "1"
        widget.value.should eq 1
      end
    end

    describe CameraWidget::Range do
      it "returns range and step" do
        widget = build_range(1, 3, 0.5)
        widget.range.should eq 1f32..3f32
        widget.step.should eq 0.5f32
      end

      it "returns choices" do
        build_range(1, 3, 0.5).choices.should eq [1, 1.5, 2, 2.5, 3]
      end

      it "accepts floats, ints and strings" do
        widget = build_range(0, 10, 1)
        widget.value = 2.5
        widget.value.should eq 2.5
        widget.value = 3
        widget.value.should eq 3
        widget.value = "4.5"
        widget.value.should eq 4.5
      end
    end

    describe CameraWidget::Date do
      it "accepts times, ints and strings" do
        widget = build_widget(:date)
        time = Time.unix(1_000_000)
        widget.value = time
        widget.value.should eq time
        widget.value = 2_000_000
        widget.value.should eq Time.unix(2_000_000)
        widget.value = time.to_s
        widget.value.should eq time
      end
    end

    describe CameraWidget::Radio do
      it "returns choices" do
        build_radio(%w(100 200 400)).choices.should eq %w(100 200 400)
      end

      it "accepts collections and regexes" do
        widget = build_radio(%w(100 200 400))
        widget.value = %w(300 400)
        widget.value.should eq "400"
        widget.value = /^2/
        widget.value.should eq "200"
      end

      it "raises if no choice matches" do
        expect_raises(ArgumentError, "No matching value found") do
          build_radio(%w(100 200)).value = /^3/
        end
      end

      it "moves the cursor" do
        widget = build_radio(%w(100 200 400))
        widget.value = "100"
        (widget >> 2).should eq "400"
        widget.value.should eq "400"
        (widget << 1).should eq "200"
        widget.value.should eq "200"
      end

      it "does not move beyond the last choice" do
        widget = build_radio(%w(100 200 400))
        widget.value = "400"
        (widget >> 1).should be_nil
        widget.value.should eq "400"
      end
    end
  end
end
