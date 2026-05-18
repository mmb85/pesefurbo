# ==============================================================================
# app/models/transfer.rb
# ==============================================================================
class Transfer < ApplicationRecord
  belongs_to :player
  belongs_to :from_club, class_name: "Club", optional: true
  belongs_to :to_club,   class_name: "Club"
  belongs_to :season

  enum :transfer_type, {
    permanent: "permanent", loan: "loan",
    loan_to_buy: "loan_to_buy", free: "free", youth_academy: "youth_academy"
  }
  enum :status, {
    negotiating: "negotiating", agreed: "agreed",
    completed: "completed", collapsed: "collapsed"
  }
end
