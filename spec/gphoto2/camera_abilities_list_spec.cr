require "../spec_helper"

module GPhoto2
  describe CameraAbilitiesList do
    it "looks up abilities by model" do
      context = Context.new
      begin
        list = CameraAbilitiesList.new(context)
        list.lookup_model(DIRECTORY_CAMERA_MODEL).should be >= 0

        abilities = list[DIRECTORY_CAMERA_MODEL]
        abilities.should be_a CameraAbilities
        abilities.folder_operations.put_file?.should be_true
      ensure
        context.close
      end
    end

    it "raises on unknown model" do
      context = Context.new
      begin
        list = CameraAbilitiesList.new(context)
        expect_raises(GPhoto2::Error) do
          list["No Such Camera 9000"]
        end
      ensure
        context.close
      end
    end
  end

  describe CameraAbilities do
    describe ".find" do
      it "returns abilities of the given model" do
        abilities = CameraAbilities.find(DIRECTORY_CAMERA_MODEL)
        abilities.status.should be_a LibGPhoto2::CameraDriverStatus
        abilities.operations.none?.should be_true
      end
    end
  end
end
