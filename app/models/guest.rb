class Guest
  class << self
    def find_or_initialize(name)
      find(name) || new(name: name)
    end

    def find(name)
      guest_attributes = MongoStore.find(collection, name: name).first
      new(guest_attributes) if guest_attributes
    end

    def all
      MongoStore.find(collection, {}).collect{|param| new(param)}
    end
  end

  attr_reader :name, :attributes

  def initialize(params)
    params = HashWithIndifferentAccess.new(params)
    @name = params[:name]
    @attributes = params[:attributes] || {}
    @old_attributes = @attributes.clone
    @id = params[:_id]
  end

  def save!
    @id.nil? ? create! : update!
  end

  def == other
    self.class == other.class and
        self.name == other.name and
        self.attributes == other.attributes
  end

  def merge_attributes(attributes)
    self.attributes.merge!(attributes)
  end

  def history
    GuestHistory.find(name)
  end

  def last_updated
    history.collect(&:timestamp).sort.last
  end

  private
  def to_params
    {name: @name, attributes: @attributes}
  end

  def self.collection
    'guest'
  end

  def collection
    self.class.collection
  end

  def update!
    MongoStore.update!(collection, @id, to_params)
    GuestHistory.guest_updated(self, ChangeSet.build(@old_attributes, attributes))
  end

  def create!
    MongoStore.create!(collection, to_params)
    GuestHistory.guest_created(self, ChangeSet.build(@old_attributes, attributes))
  end
end
