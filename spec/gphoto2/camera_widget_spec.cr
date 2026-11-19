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

      describe "#to_s" do
        it "returns string representation of the value" do
          widget = build_widget(:toggle)
          widget.value = 1
          widget.to_s.should eq "1"
        end

        it "returns empty string for widgets without value" do
          build_widget(:window).to_s.should eq ""
          build_widget(:button).to_s.should eq ""
        end
      end

      describe "#==(other : self)" do
        it "compares type, name and value" do
          a, b = build_widget(:text, "foo"), build_widget(:text, "foo")
          a.value = b.value = "bar"
          a.should eq b
          b.value = "baz"
          a.should_not eq b
          a.should_not eq build_widget(:text, "other")
        end

        it "compares widgets without value" do
          build_widget(:window, "main").should eq build_widget(:window, "main")
          build_widget(:button, "a").should_not eq build_widget(:button, "b")
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

        it "checks against numeric ranges" do
          widget = build_widget(:text)
          widget.value = "5.6"
          widget.in?(4..7.1).should be_true
          widget.in?(4.0..5.0).should be_false
          widget.in?(..6).should be_true
          widget.in?(6..).should be_false
        end

        it "returns false for non-numeric value in numeric range" do
          widget = build_widget(:text)
          widget.value = "Auto"
          widget.in?(1..2).should be_false
        end

        it "checks against string ranges" do
          widget = build_widget(:text)
          widget.value = "b"
          widget.in?("a".."c").should be_true
          widget.in?("c".."d").should be_false
        end

        it "checks against time ranges" do
          widget = build_widget(:date)
          widget.value = Time.unix(1_000)
          widget.in?(Time.unix(0)..Time.unix(2_000)).should be_true
          widget.in?(Time.unix(2_000)..).should be_false
        end

        it "returns false for empty value" do
          build_widget(:text).in?(1..2).should be_false
        end
      end

      describe "#close" do
        it "frees the widget" do
          widget = build_widget(:text)
          widget.close
          widget.ptr?.should be_nil
        end

        it "does not free child widgets" do
          window = build_widget(:window, "main")
          GPhoto2.check! LibGPhoto2.gp_widget_append(window, build_widget(:text, "owner"))

          child = window.children.first
          child.close
          child.ptr?.should be_truthy
          child.name.should eq "owner"
          window.close
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

      it "returns choices without floating-point drift" do
        build_range(0, 1, 0.1).choices.should eq [
          0f32, 0.1f32, 0.2f32, 0.3f32, 0.4f32, 0.5f32,
          0.6f32, 0.7f32, 0.8f32, 0.9f32, 1f32,
        ]
      end

      it "does not exceed the upper bound" do
        build_range(0, 1, 0.3).choices.should eq [0f32, 0.3f32, 0.6f32, 0.9f32]
      end

      it "returns bounds for zero increment" do
        build_range(1, 5, 0).choices.should eq [1, 5]
        build_range(2, 2, 0).choices.should eq [2]
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

      it "accepts collections of numbers and symbols" do
        widget = build_radio(%w(100 200 Auto))
        widget.value = [300, 200]
        widget.value.should eq "200"
        widget.value = {:manual, :auto}
        widget.value.should eq "Auto"
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

      it "moves the cursor from an empty value" do
        widget = build_radio(%w(None 100 200))
        widget.value = "None"
        (widget >> 1).should eq "100"
        (widget << 1).should eq "None"
      end

      it "does not move before the first choice" do
        widget = build_radio(%w(100 200 400))
        widget.value = "100"
        (widget << 1).should be_nil
        widget.value.should eq "100"
      end
    end
  end
end
