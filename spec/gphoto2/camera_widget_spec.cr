require "../spec_helper"

module GPhoto2
  describe CameraWidget do
    describe ".factory" do
      it "builds widget of a matching class" do
        {% for type in %w[Window Section Text Range Toggle Radio Menu Button Date] %}
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

      it "treats any non-zero readonly flag as set" do
        widget = build_widget(:text)
        GPhoto2.check! LibGPhoto2.gp_widget_set_readonly(widget, 2)
        widget.readonly?.should be_true
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
          widget.value = "NONE"
          widget.value.should be_nil
          widget.value = "Nonetheless"
          widget.value.should eq "Nonetheless"
        end

        it "returns zero values" do
          widget = build_widget(:toggle)
          widget.value = 0
          widget.value.should eq 0
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

      describe "#inspect" do
        it "returns the name and value of the widget" do
          widget = build_radio(%w[100 200], "iso")
          widget.value = "200"
          widget.inspect.should eq %(#<GPhoto2::CameraWidget::Radio name="iso" value="200">)
          build_widget(:window, "main").inspect.should eq %(#<GPhoto2::CameraWidget::Window name="main" value=nil>)
        end

        it "leaves out the ancestors of the widget" do
          window = build_widget(:window, "main")
          LibGPhoto2.gp_widget_append(window, build_widget_ptr(:toggle, "flash"))
          child = window.children.first
          child.inspect.should eq %(#<GPhoto2::CameraWidget::Toggle name="flash" value=0>)
          child.pretty_inspect.should eq child.inspect
        end

        it "doesn't raise for closed widgets" do
          widget = build_widget(:text)
          widget.close
          widget.inspect.should eq "#<GPhoto2::CameraWidget::Text (closed)>"
        end

        it "doesn't show the cached details of closed widgets" do
          window = build_widget(:window, "main")
          LibGPhoto2.gp_widget_append(window, build_widget_ptr(:toggle, "flash"))
          child = window.children.first
          window.inspect
          child.inspect
          window.close
          window.inspect.should eq "#<GPhoto2::CameraWidget::Window (closed)>"
          child.inspect.should eq "#<GPhoto2::CameraWidget::Toggle (closed)>"
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

      describe "#hash" do
        it "is consistent with equality" do
          a, b = build_widget(:text, "foo"), build_widget(:text, "foo")
          a.value = b.value = "bar"
          a.hash.should eq b.hash
          Set{a, b}.size.should eq 1
          Set{build_widget(:window, "main"), build_widget(:window, "main")}.size.should eq 1
        end

        it "does not change along with the value" do
          widget = build_widget(:text, "foo")
          hash = widget.hash
          widget.value = "bar"
          widget.hash.should eq hash
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

        it "compares the values representing no value as they are" do
          widget = build_widget(:text)
          widget.value = "None"
          widget.value.should be_nil
          (widget == "None").should be_true
          (widget == :none).should be_true
          widget.in?(["None"]).should be_true
          # As before
          (widget == "").should be_true
          (widget == "Auto").should be_false
        end

        it "compares value with symbol" do
          widget = build_widget(:text)
          widget.value = "Automatic"
          (widget == :automatic).should be_true
        end

        it "compares value with symbol case-insensitively" do
          widget = build_widget(:text)
          widget.value = "auto"
          (widget == :auto).should be_true
          widget.value = "Auto ISO"
          (widget == :auto_iso).should be_true
          (widget == :auto).should be_false
          widget.in?([:manual, :auto_iso]).should be_true
        end
      end

      describe "#in?" do
        it "checks integers against numeric ranges exactly" do
          widget = build_widget(:text)
          widget.value = "9007199254740993"
          widget.in?(9007199254740992_i64..9007199254740992_i64).should be_false
          widget.in?(9007199254740993_i64..9007199254740994_i64).should be_true
          widget.in?(9007199254740990_i64..).should be_true
          widget.in?(..9007199254740992_u64).should be_false
          widget.value = "4"
          widget.in?(3.5..4.5).should be_true
          widget.value = "4.5"
          widget.in?(4..5).should be_true
          widget.in?(5..6).should be_false
        end

        it "checks against collections" do
          widget = build_widget(:text)
          widget.value = "Manual"
          widget.in?(%w[Manual Bulb]).should be_true
          widget.in?(%w[Auto]).should be_false
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

      describe "#finalize" do
        it "frees root widgets" do
          widget = build_widget(:text)
          widget.finalize
          widget.ptr?.should be_nil
        end

        it "keeps the tree alive while child widgets are referenced" do
          # Don't keep a reference to the window itself
          child = -> {
            window = build_widget(:window, "main")
            GPhoto2.check! LibGPhoto2.gp_widget_append(window, build_widget_ptr(:text, "owner"))
            window.children.first
          }.call

          GC.collect
          child.parent.try(&.ptr?).should be_truthy
          child.name.should eq "owner"
        end
      end

      describe "#close" do
        it "frees the widget" do
          widget = build_widget(:text)
          widget.close
          widget.ptr?.should be_nil
        end

        it "does not free unowned widgets" do
          ptr = build_widget_ptr(:text)
          begin
            widget = CameraWidget.factory(ptr, owned: false)
            widget.close
            widget.ptr?.should eq ptr
          ensure
            LibGPhoto2.gp_widget_free(ptr)
          end
        end

        it "makes the widget unusable" do
          widget = build_widget(:text)
          widget.close
          expect_raises(GPhoto2::Exception, "Widget has been closed") do
            widget.value
          end
        end

        it "makes child widgets of a closed root unusable" do
          window = build_widget(:window, "main")
          GPhoto2.check! LibGPhoto2.gp_widget_append(window, build_widget_ptr(:text, "owner"))

          child = window.children.first
          window.close
          expect_raises(GPhoto2::Exception, "Widget has been closed") do
            child.value = "foo"
          end
          expect_raises(GPhoto2::Exception, "Widget has been closed") do
            child.wrapped
          end
        end

        it "refuses to make child widgets owned" do
          window = build_widget(:window, "main")
          child_ptr = build_widget_ptr(:text, "owner")
          GPhoto2.check! LibGPhoto2.gp_widget_append(window, child_ptr)

          expect_raises(ArgumentError, "Child widgets can't own their memory") do
            CameraWidget.factory(child_ptr, window, owned: true)
          end
        end

        it "does not free child widgets" do
          window = build_widget(:window, "main")
          GPhoto2.check! LibGPhoto2.gp_widget_append(window, build_widget_ptr(:text, "owner"))

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
          section = build_widget_ptr(:section, "settings")
          text = build_widget_ptr(:text, "owner")
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

      it "rejects values out of the C int range" do
        widget = build_widget(:toggle)
        widget.value = 1
        expect_raises(ArgumentError, "Invalid value: 9223372036854775807") do
          widget.value = Int64::MAX
        end
        widget.value.should eq 1
      end

      it "compares with booleans" do
        widget = build_widget(:toggle)
        widget.value = true
        (widget == true).should be_true
        (widget == false).should be_false
        widget.value = false
        (widget == false).should be_true
        widget.in?({true}).should be_false
      end

      it "accepts and compares with symbols" do
        widget = build_widget(:toggle)
        widget.value = :on
        widget.value.should eq 1
        (widget == :on).should be_true
        (widget == :yes).should be_true
        (widget == :off).should be_false
        widget.in?([:off, :true]).should be_true
        widget.value = :Off
        widget.value.should eq 0
        (widget == :off).should be_true
        (widget == :maybe).should be_false
        expect_raises(ArgumentError, "Invalid value: :maybe") do
          widget.value = :maybe
        end
      end

      it "compares with strings" do
        widget = build_widget(:toggle)
        widget.value = "on"
        (widget == "on").should be_true
        (widget == " Yes ").should be_true
        (widget == "1").should be_true
        (widget == "off").should be_false
        (widget == "maybe").should be_false
        widget.in?(%w[off true]).should be_true
      end

      it "accepts boolean strings" do
        widget = build_widget(:toggle)
        widget.value = "true"
        widget.value.should eq 1
        widget.value = "False"
        widget.value.should eq 0
      end

      it "accepts on/off and yes/no strings" do
        widget = build_widget(:toggle)
        {"on" => 1, "Off" => 0, "YES" => 1, " no " => 0}.each do |value, expected|
          widget.value = value
          widget.value.should eq expected
        end
      end
    end

    describe CameraWidget::Range do
      it "compares the value with numeric strings numerically" do
        widget = build_range(-1_f32, 1_f32, 0.1_f32)
        widget.value = "0.30"
        (widget == "0.30").should be_true
        (widget == "0.3").should be_true
        (widget == " 0.3 ").should be_true
        (widget == "0.4").should be_false
        (widget == "abc").should be_false
      end

      it "returns range and step" do
        widget = build_range(1, 3, 0.5)
        widget.range.should eq 1f32..3f32
        widget.step.should eq 0.5f32
      end

      it "returns choices" do
        build_range(1, 3, 0.5).choices.should eq [1, 1.5, 2, 2.5, 3]
      end

      it "returns only the bounds for NaN increment" do
        build_range(1, 3, Float32::NAN).choices.should eq [1, 3]
      end

      it "does not raise for NaN bounds" do
        build_range(Float32::NAN, 3, 1).choices.size.should eq 2
        build_range(1, Float32::NAN, 1).choices.size.should eq 2
      end

      it "returns choices without floating-point drift" do
        build_range(0, 1, 0.1).choices.should eq [
          0f32, 0.1f32, 0.2f32, 0.3f32, 0.4f32, 0.5f32,
          0.6f32, 0.7f32, 0.8f32, 0.9f32, 1f32,
        ]
      end

      it "does not exceed the upper bound" do
        build_range(0, 1, 0.3).choices.should eq [0f32, 0.3f32, 0.6f32, 0.9f32]
        build_range(0, 0.99995, 1).choices.should eq [0f32]
        build_range(0, 1, 1).choices.should eq [0f32, 1f32]
      end

      it "keeps the upper bound despite roundoff errors" do
        build_range(-0.3, 0, 0.1).choices.should eq [-0.3f32, -0.2f32, -0.1f32, 0f32]
        build_range(-1, 0, 0.1).choices.last.should eq 0f32
        build_range(0.1, 0.7, 0.2).choices.should eq [0.1f32, 0.3f32, 0.5f32, 0.7f32]
      end

      it "returns choices up to the limit" do
        max = CameraWidget::Range::MAX_CHOICES - 1
        build_range(1, max.to_f32, 1).choices.size.should eq max
      end

      it "raises on too many choices" do
        expect_raises(GPhoto2::Exception, "Too many choices") do
          build_range(0, 4294967295, 1).choices
        end
      end

      it "returns bounds for zero increment" do
        build_range(1, 5, 0).choices.should eq [1, 5]
        build_range(2, 2, 0).choices.should eq [2]
      end

      it "rejects non-finite and out of range values" do
        widget = build_range(0, 10, 1)
        widget.value = 5
        [Float32::NAN, Float64::INFINITY, -Float64::INFINITY, 1e300, "nan", "-inf"].each do |value|
          expect_raises(ArgumentError, "Invalid value") do
            widget.value = value
          end
        end
        widget.value.should eq 5
      end

      it "compares the value with numbers numerically" do
        widget = build_range(-5, 5, 0.1)
        widget.value = 3
        (widget == 3).should be_true
        (widget == 3.0).should be_true
        (widget == 4).should be_false
        widget.value = 0.3
        (widget == 0.3).should be_true
        (widget == 0.3_f32).should be_true
        widget.in?([1, 0.3]).should be_true
        # Other objects are still compared as strings
        (widget == "0.3").should be_true
      end

      it "compares the value with numbers rounded the way they're set" do
        widget = build_range(-Float32::MAX, Float32::MAX, 0_f32)
        widget.value = 1.0 / 3
        (widget == 1.0 / 3).should be_true
        widget.value = Int32::MAX
        (widget == Int32::MAX).should be_true
        widget.in?([Int32::MAX]).should be_true
        (widget == 1e300).should be_false
        (widget == Float64::NAN).should be_false
        (widget == UInt128::MAX).should be_false
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

      it "compares the value with times regardless of their location" do
        widget = build_widget(:date)
        time = Time.unix(1_000_000)
        widget.value = time
        (widget == time).should be_true
        (widget == time.in(Time::Location.fixed(3600))).should be_true
        (widget == time + 1.second).should be_false
      end

      it "compares the value with Unix timestamps" do
        widget = build_widget(:date)
        widget.value = 1_000_000
        (widget == 1_000_000).should be_true
        (widget == 1_000_000_u64).should be_true
        (widget == 1_000_001).should be_false
        (widget == Int64::MAX).should be_false
        (widget == UInt64::MAX).should be_false
        widget.in?([0, 1_000_000]).should be_true
      end

      it "checks the value against ranges of Unix timestamps" do
        widget = build_widget(:date)
        widget.value = 1_000_000
        widget.in?(0..2_000_000).should be_true
        widget.in?(1_000_001..).should be_false
        widget.in?(..1_000_000_u64).should be_true
      end

      it "compares the value with time strings" do
        widget = build_widget(:date)
        widget.value = "2020-01-02T03:04:05Z"
        (widget == "2020-01-02T03:04:05Z").should be_true
        (widget == "2020-01-02T04:04:05+01:00").should be_true
        (widget == "2020-01-02 03:04:05 UTC").should be_true
        (widget == "2020-01-02T03:04:06Z").should be_false
        (widget == "yesterday").should be_false
        (widget == "2020-02-30 03:04:05 UTC").should be_false
      end

      it "accepts ISO 8601 strings" do
        widget = build_widget(:date)
        widget.value = "2020-01-02T03:04:05Z"
        widget.value.should eq Time.utc(2020, 1, 2, 3, 4, 5)
        widget.value = "2020-01-02T03:04:05+01:00"
        widget.value.should eq Time.utc(2020, 1, 2, 2, 4, 5)
      end

      it "raises on times out of the C int range" do
        widget = build_widget(:date)
        widget.value = Time.unix(Int32::MAX)
        widget.value.should eq Time.unix(Int32::MAX)

        expect_raises(ArgumentError, "Time out of range: 2040-01-01 00:00:00 UTC") do
          widget.value = Time.utc(2040, 1, 1)
        end
        expect_raises(ArgumentError, "Time out of range") do
          widget.value = Int32::MIN.to_i64 - 1
        end
        # Out of the range supported by `Time` as well
        {Int64::MAX, Int64::MIN, UInt64::MAX}.each do |value|
          expect_raises(ArgumentError, "Time out of range: #{value}") do
            widget.value = value
          end
        end
        widget.value.should eq Time.unix(Int32::MAX)
      end

      it "raises on invalid strings" do
        expect_raises(Time::Format::Error) do
          build_widget(:date).value = "yesterday"
        end
      end
    end

    describe CameraWidget::Radio do
      it "returns choices" do
        build_radio(%w[100 200 400]).choices.should eq %w[100 200 400]
      end

      it "accepts collections and regexes" do
        widget = build_radio(%w[100 200 400])
        widget.value = %w[300 400]
        widget.value.should eq "400"
        widget.value = /^2/
        widget.value.should eq "200"
      end

      it "picks the first matching value of the collection" do
        widget = build_radio(%w[100 200 400])
        widget.value = %w[400 200]
        widget.value.should eq "400"
        widget.value = [300, 200, 100].each
        widget.value.should eq "200"
      end

      it "compares the value with numbers numerically" do
        widget = build_radio(%w[4 5.6 0.3 1/60])
        widget.value = "4"
        (widget == 4).should be_true
        (widget == 4.0).should be_true
        (widget == 5.6).should be_false
        widget.in?([8, 4.0]).should be_true
        widget.value = "0.3"
        (widget == 0.3_f32).should be_true
        widget.value = "1/60"
        (widget == 0).should be_false
        (widget == "1/60").should be_true
      end

      it "compares the value with integers exactly" do
        widget = build_widget(:text)
        widget.value = "9007199254740992"
        (widget == 9007199254740992_i64).should be_true
        (widget == 9007199254740993_i64).should be_false
      end

      it "matches symbols with the choices case-insensitively" do
        widget = build_radio(["auto", "Auto ISO", "AWB"])
        widget.value = :auto
        widget.value.should eq "auto"
        widget.value = :auto_iso
        widget.value.should eq "Auto ISO"
        widget.value = [:daylight, :awb]
        widget.value.should eq "AWB"
        # Symbols not among the choices are set capitalized, as before
        widget.value = :manual
        widget.value.should eq "Manual"
      end

      it "matches numbers with the choices numerically" do
        widget = build_radio(%w[2.8 4 5.6 1/60])
        widget.value = 4.0
        widget.value.should eq "4"
        widget.value = 5.6_f32
        widget.value.should eq "5.6"
        widget.value = [8, 4.0_f32]
        widget.value.should eq "4"
        # Numbers not among the choices are set as-is
        widget.value = 11
        widget.value.should eq "11"
      end

      it "matches integers with the choices exactly" do
        widget = build_radio(%w[9007199254740992 9007199254740993 4.0])
        widget.value = 9007199254740993_i64
        widget.value.should eq "9007199254740993"
        widget.value = [9007199254740993_i64]
        widget.value.should eq "9007199254740993"
        widget.value = 4
        widget.value.should eq "4.0"
      end

      it "accepts collections of numbers and symbols" do
        widget = build_radio(%w[100 200 Auto])
        widget.value = [300, 200]
        widget.value.should eq "200"
        widget.value = {:manual, :auto}
        widget.value.should eq "Auto"
      end

      it "accepts iterators" do
        widget = build_radio(%w[100 200 Auto])
        widget.value = [300, 200].each
        widget.value.should eq "200"
        widget.value = {:manual, :auto}.each
        widget.value.should eq "Auto"
      end

      it "raises if no choice matches" do
        expect_raises(ArgumentError, "No matching value found") do
          build_radio(%w[100 200]).value = /^3/
        end
      end

      it "moves the cursor" do
        widget = build_radio(%w[100 200 400])
        widget.value = "100"
        (widget >> 2).should eq "400"
        widget.value.should eq "400"
        (widget << 1).should eq "200"
        widget.value.should eq "200"
      end

      it "does not move beyond the last choice" do
        widget = build_radio(%w[100 200 400])
        widget.value = "400"
        (widget >> 1).should be_nil
        widget.value.should eq "400"
      end

      it "moves the cursor from an empty value" do
        widget = build_radio(%w[None 100 200])
        widget.value = "None"
        (widget >> 1).should eq "100"
        (widget << 1).should eq "None"
      end

      it "does not overflow when moving far out of bounds" do
        widget = build_radio(%w[100 200 400])
        widget.value = "200"
        (widget >> Int32::MAX).should be_nil
        (widget << Int32::MAX).should be_nil
        (widget << Int32::MIN).should be_nil
        widget.move_by(Int32::MIN).should be_nil
        widget.value.should eq "200"
      end

      it "does not move before the first choice" do
        widget = build_radio(%w[100 200 400])
        widget.value = "100"
        (widget << 1).should be_nil
        widget.value.should eq "100"
      end
    end
  end
end
