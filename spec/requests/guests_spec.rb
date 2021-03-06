require 'spec_helper'

describe 'Guests' do
  describe 'GET /guests/:guest_name' do
    it 'shows the parameters of the guests saved' do
      put guest_path('XX1'), {guest: {size: '100cm', weight: '10kg'}}

      get guest_path('XX1')

      expect(response.status).to eq(200)
      expect(response.body).to eq({size: '100cm', weight: '10kg'}.to_json)
    end
  end

  describe 'PUT /guests/:guest_name' do
    it 'creates a guest when one dosent exist' do
      put guest_path('XX1'), {guest: {size: '100cm', weight: '10kg'}}

      expect(response.status).to eq(204)
      get guest_path('XX1')
      expect(response.body).to eq({size: '100cm', weight: '10kg'}.to_json)
    end

    it 'should update the attributes if guest already exists' do
      put guest_path('XX1'), {guest: {size: '100cm', weight: '10kg'}}

      put guest_path('XX1'), {guest: {size: '101cm', eyes: '2'}}

      expect(response.status).to eq(204)
      get guest_path('XX1')
      expect(response.body).to eq({size: '101cm', weight: '10kg', eyes: '2'}.to_json)
    end
  end

  describe 'GET /guests' do
    it 'gives the list on guests with the last updated time' do
      Timecop.freeze(Time.parse('12 Dec 2234 13:04:12')) do
        put guest_path('XX1'), {guest: {size: '100cm', weight: '10kg'}}
      end
      last_update_time_for_xx1 = Time.parse('12 Dec 2235 13:04:12')
      Timecop.freeze(last_update_time_for_xx1) do
        put guest_path('XX1'), {guest: {size: '101cm'}}
      end

      last_update_time_for_xx2 = Time.parse('12 Dec 2231 13:04:12')
      Timecop.freeze(last_update_time_for_xx2) do
        put guest_path('XX2'), {guest: {size: '100cm', weight: '10kg'}}
      end

      get guests_path

      expect(response.body).to eq([{name: 'XX1', last_update: last_update_time_for_xx1.utc},
                                   {name: 'XX2', last_update: last_update_time_for_xx2.utc}].to_json)
    end
  end

  describe 'GET /guest/:guest_name/history' do
    it 'gives the list of changes to the guest attributes' do
      Timecop.freeze(Time.parse('12 Dec 2234 13:04:12')) do
        put guest_path('XX1'), {guest: {size: '100cm', weight: '10kg'}}
      end

      Timecop.freeze(Time.parse('12 Dec 2250 07:10:00')) do
        put guest_path('XX1'), {guest: {size: '100cm', weight: '4kg', ears: '1'}}
      end

      get history_guest_path('XX1')
      expect(response.body).to eq([
                                      {timestamp: Time.parse('12 Dec 2234 13:04:12').utc,
                                       type: 'created',
                                       changes: [
                                           {attribute: 'size', from: nil, to: '100cm'},
                                           {attribute: 'weight', from: nil, to: '10kg'}
                                       ]
                                      },
                                      {timestamp: Time.parse('12 Dec 2250 07:10:00').utc,
                                       type: 'updated',
                                       changes: [
                                           {attribute: 'weight', from: '10kg', to: '4kg'},
                                           {attribute: 'ears', from: nil, to: '1'}
                                       ]
                                      },
                                  ].to_json)
    end
  end
end
