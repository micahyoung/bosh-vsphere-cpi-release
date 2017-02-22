module VSphereCloud
  module Resources
    class PersistentDisk
      # https://pubs.vmware.com/vsphere-55/index.jsp?topic=%2Fcom.vmware.wssdk.apiref.doc%2Fvim.VirtualDiskManager.VirtualDiskType.html
      SUPPORTED_DISK_TYPES = %w{
        eagerZeroedThick
        preallocated
        thick
        thin
      }

      attr_reader :cid, :size_in_mb, :datastore, :folder

      def initialize(cid:, size_in_mb:, datastore:, folder:)
        @cid = cid
        @size_in_mb = size_in_mb
        @datastore = datastore
        @folder = folder
      end

      def path
        "[#{@datastore.name}] #{@folder}/#{@cid}.vmdk"
      end

      def create_disk_attachment_spec(disk_controller_id:, existing_disk:)
        virtual_disk = Helpers::Disks.create_virtual_disk(
          disk_controller_id: disk_controller_id,
          size_in_mb: @size_in_mb,
          backing: create_persistent_backing(existing_disk),
        )
        virtual_disk.capacity_in_kb = 0

        device_config_spec = Resources::VM.create_add_device_spec(virtual_disk)
        device_config_spec.file_operation = VimSdk::Vim::Vm::Device::VirtualDeviceSpec::FileOperation::CREATE

        device_config_spec
      end

      private

      def create_persistent_backing(existing_disk)
        parent_backing_info = VimSdk::Vim::Vm::Device::VirtualDisk::FlatVer2BackingInfo.new
        parent_backing_info.datastore = @datastore.mob
        parent_backing_info.file_name = existing_disk.path

        backing_info = VimSdk::Vim::Vm::Device::VirtualDisk::FlatVer2BackingInfo.new
        backing_info.datastore = @datastore.mob
        backing_info.file_name = path.gsub(/\.vmdk/, '_1.vmdk')
        backing_info.parent = parent_backing_info

        backing_info.disk_mode = VimSdk::Vim::Vm::Device::VirtualDiskOption::DiskMode::INDEPENDENT_PERSISTENT

        backing_info
      end
    end
  end
end
