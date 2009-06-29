class VotersController < ApplicationController
  before_filter :force_xml

  # POST /voters/add
  # ==== Return
  # Added voter.
  # ==== Post
  # XML of voter to add.
  def add
    return unless request.post?
    xml = LibXML::XML::Parser.parse(request.raw_post)
    @voters = xml.find("/voters/voter").inject([]) do |voters, voter|
      cur_voter = Voter.create(:user_id => current_user.id)
      voter.find("features/feature").each do |feature|
        Feature.create(:voter_id => cur_voter.id, :name => feature.attributes["name"], :value => feature.content.to_i)
      end
      voters << cur_voter
    end
  end

  # GET /voters/list
  # ==== Return
  # List of user's voters.
  def list
    @voters = Voter.all(:conditions => { :user_id => current_user.id }, :include => :features)
  end

  # GET /voters/set/1
  # ==== Return
  # Voter.
  # ==== Options (params)
  # id<String>:: Converted to integer. Id of voter to set. Must belong to user.
  # {}<Hash>:: Name, value pairs of features to set. Any non spaces or
  # alphanumerics plus _ are removed from name.
  # ==== Raises
  # PermissionError:: If voter does not belong to user.
  def set
    p = params.clone
    @voter = Voter.find(p.delete(:id).to_i, :conditions => { :user_id => current_user.id }, :include => :features)
    raise PermissionError unless @voter
    p.delete(:action)
    p.delete(:controller)
    p.delete(:format)
    p.each do |name, value|
      # only space, alphanumerics, or _
      name = name.gsub(/[^(' '|\w)]/, '')
      feature = Feature.first(:conditions => { :voter_id => @voter.id, :name => name })
      if feature
        feature.update_attribute(:value, value.to_i)
      else
        feature = Feature.new(:name => name, :value => value.to_i)
        @voter.features << feature
      end
    end
  end
end