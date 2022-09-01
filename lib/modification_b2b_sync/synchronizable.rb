module ModificationB2bSync

  Synchronizable = Struct.new(:name, :parent) do
    def to_s
      name
    end

    def self.all
      synchronizing_data = [Synchronizable.new(:all)]
      ::EasyRakeTaskB2bSynchronizing::B2B_TYPES.map do |type|
        synchronizing_data << Synchronizable.new(type, :all)
      end
      synchronizing_data
    end
  end

end
