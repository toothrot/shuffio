class Team < ApplicationRecord
  after_create :set_default_elo

  has_and_belongs_to_many :divisions
  has_many :seasons, through: :divisions
  has_many :championships, class_name: 'Season', foreign_key: 'champion_id'

  def set_default_elo
    self.elo_cache = starting_elo || 1000
    self.previous_elo = starting_elo || 1000
    save
  end

  def matches
    Match.where(away_team_id: id).or(Match.where(home_team_id: id))
  end

  def match_count
    return matches.count unless starting_match_count

    matches.count + starting_match_count
  end

  def record(team_matches = nil)
    if team_matches
      record = { wins: 0, losses: 0 }
    else
      record = { wins: starting_wins, losses: starting_losses }
      team_matches = matches
    end

    return record unless team_matches.any?

    team_matches.each do |m|
      if m.winner.nil?
        # do nothing
      elsif m.winner == self
        record[:wins] += 1
      else
        record[:losses] += 1
      end
    end

    record
  end

  def league_record(division = nil)
    # If Division specified, return record from this division
    # Else, return record from _all_ division games
    division ? record(matches.where(division: division)) : record(matches.where.not(division: nil))
  end

  def self.reset_all_elo
    Team.all.find_each(&:set_default_elo)
  end

  def display_name
    short_name || name
  end

  def logo_uri
    image_uri || ActionController::Base.helpers.image_url('tangs-biscuit-padded.png')
  end

  def color
    ColorGenerator.new(saturation: 0.75, value: 1.0, seed: id).create_hex
  end

  def champion?
    championships.any?
  end
end
