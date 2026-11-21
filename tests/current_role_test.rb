# frozen_string_literal: true

# The site states the author's current employer and no longer offers freelance
# or contract work.
#
# Bit Pond stays on the CV as a current entry: the author remains its director,
# but the company is shelved and does not trade. So the assertions pin order
# (Glue Reply first) rather than Bit Pond's absence.

require_relative "test_helper"

class CurrentRoleTest < Minitest::Test
  EMPLOYER = "Glue Reply"
  ROLE = "Senior Consultant – Solution Architect"

  def pages
    BuiltSite.pages
  end

  def cv_entries
    pages["/cv/"].css(".cv-entry")
  end

  def test_cv_leads_with_the_current_role
    first = cv_entries.first
    refute_nil first, "the CV has no entries"

    assert_equal EMPLOYER, first.css(".cv-company").text.strip
    assert_equal ROLE, first.css(".cv-role").text.strip
    assert_match(/Present\z/, first.css(".cv-date").text.strip)
  end

  def test_bit_pond_follows_as_a_shelved_current_entry
    second = cv_entries[1]
    refute_nil second, "the CV has only one entry"

    assert_equal "Bit Pond", second.css(".cv-company").text.strip
    assert_equal "Director", second.css(".cv-role").text.strip
    assert_match(/Present\z/, second.css(".cv-date").text.strip)
    refute_match(/consult/i, second.css(".cv-description").text,
                 "Bit Pond must not read as a consulting business")
  end

  def test_home_page_names_the_current_employer
    text = pages["/"].css("main.main").text

    assert_includes text, EMPLOYER
  end

  def test_no_page_offers_freelance_or_contract_work
    pages.each do |url, document|
      text = document.text

      refute_match(/freelanc/i, text, "#{url} still mentions freelance work")
      refute_match(/contract work/i, text, "#{url} still offers contract work")
    end
  end
end
