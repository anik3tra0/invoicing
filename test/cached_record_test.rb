require_relative 'test_helper'

class CachedRecordTest < MiniTest::Unit::TestCase
  # Classes which this test uses
  class CachedRecord < ActiveRecord::Base
    acts_as_cached_record id: 'id'
    has_many :referrers, class_name: 'RefersToCachedRecord', foreign_key: 'cached_record_id'
  end

  class RefersToCachedRecord < ActiveRecord::Base
    belongs_to :cached_record
  end

  # TODO: Difficult to mock AR connection, fix it
  class CachedRecordMockDatabase < ActiveRecord::Base
    self.table_name = "cached_records"
    acts_as_cached_record
  end

  # Rebuild cache after doing a transaction rollback
  def setup
    super
    CachedRecord.reload_cache
  end

  # ----------    Acutal tests begin here    ---------
  def test_find_with_valid_id_should_return_record
    record = CachedRecord.find(1)
    refute_nil record
    assert_kind_of CachedRecord, record
  end

  def test_find_with_invalid_id_should_raise_exception
    assert_raises ActiveRecord::RecordNotFound do
      CachedRecord.find(99)
    end
  end

  # def test_find_with_valid_id_should_not_access_database
  #   CachedRecordMockDatabase.connection.should_receive(:select).and_throw('should not access database')
  #   assert_not_nil CachedRecordMockDatabase.find(1)
  # end

  # def test_find_with_invalid_id_should_not_access_database
  #   CachedRecordMockDatabase.connection.should_receive(:select).and_throw('should not access database')
  #   assert_raise ActiveRecord::RecordNotFound do
  #     CachedRecordMockDatabase.find(99)
  #   end
  # end

  def test_find_with_conditions_should_still_work
    assert_equal CachedRecord.find_by_value('Two'), CachedRecord.find(2)
  end

  def test_find_without_ids_should_raise_exception
    assert_raises ActiveRecord::RecordNotFound do
      CachedRecord.find
    end
  end

  # TODO: Find from ids is not hit!
  # Find shouldn't take an array or conditions. The whole concept of
  # cached_record needs to be revisited
  # def test_find_with_empty_list_of_ids_should_raise_exception
  #   assert_raises ActiveRecord::RecordNotFound do
  #     CachedRecord.find(:conditions => {:id => []})
  #   end
  # end

  def test_find_with_list_of_ids_should_return_list_of_objects
    expected = CachedRecord.cached_record_list.sort
    assert_equal expected, CachedRecord.find([1,2])
  end

  def test_cached_record_associations_should_still_work
    assert_equal 2, CachedRecord.find(1).referrers.length
  end

  def test_foreign_key_to_cached_record_should_use_cache
    assert_equal RefersToCachedRecord.find(1).cached_record, CachedRecord.find(1)
  end

  def test_cached_record_list_should_return_all_objects
    assert_equal 2, CachedRecord.cached_record_list.length
  end

  # def test_cached_record_list_should_not_access_database
  #   CachedRecordMockDatabase.connection.should_receive(:select).and_throw('should not access database')
  #   assert_not_nil CachedRecordMockDatabase.cached_record_list
  # end

  def test_reload_cache_should_do_what_it_says_on_the_tin
    CachedRecord.create!(value: "Three")
    CachedRecord.reload_cache
    record = CachedRecord.find(3)

    refute_nil record
    assert_kind_of CachedRecord, record
    assert_equal 3, CachedRecord.cached_record_list.length
  end
end
