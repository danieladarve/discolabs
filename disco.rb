require 'httparty'
require 'dotenv/load'

class Disco

  attr_accessor :total_score, :parsed_md

  def initialize(md_file)
    # Setup API VARS
    @api_client_id = ENV['API_CLIENT_ID']
    @api_secret = ENV['API_SECRET']
    @api_base = ENV['API_BASE']
    @api_path = ENV['API_PATH']

    # Setup Score VARS
    @score_bonus = %w[D I S C O]
    @scores = setup_scores
    @total_score = 0
    @parsed_md = ""
    @md_file_name = md_file

    # Setup md file
    calculate_md_score(@md_file_name)

    # Define payload
    @payload = {
      :data => {
        :type => 'application',
        :attributes => {
          :cover_letter => @parsed_md,
          :cv_url => 'https://drive.google.com/file/d/1ZMIofgU6QNBaANsKEfpBv9dmJCOOxh06/view?usp=sharing',
          :disco_score => @total_score,
          :github_profile => 'https://github.com/danieladarve/discolabs',
          :linked_in_profile => 'www.linkedin.com/in/daniel-g-adarve-0a55361b2',
          :phone_number => '0424607951',
          :role_id => 'e0198f51-88d4-4484-99f8-f2435608dc95',
        }
      }
    }
  end

  # creates an array from A to Z and scores each letter from 0 to 4
  def setup_scores
    score = -1
    ('A' .. 'Z').to_a.map!{
      |l|
      score += 1
      result = [l, score]
      if score == 4
        score = -1;
      end
      result
    }
  end

  # Returns the char score if found in dictionary
  def get_character_score(char)
    value = @scores.find_all { |el| el[0] == char.upcase }
    score = value.size > 0 ? value[0][1]:0
    score + ((@score_bonus.include? char.upcase) ? 5 : 0)
  end

  # Calculates the total score of an
  # MD file by looping line by line and each char in the line
  def calculate_md_score(md_file_name)
    File.foreach("#{__dir__}/#{md_file_name}") do |line|
      @parsed_md += line
      line.each_byte do |i|
        @total_score += get_character_score(i.chr)
      end
    end
  end

  # returns HMAC hash and headers
  def get_headers(body)
    # Create HMAC and base64 encode it
    hmac = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), @api_secret, body.to_json))

    # Set Headers
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => "hmac #{@api_client_id}:#{hmac}"
    }
  end

  # Gets the headers and posts payload to API
  def post_payload
    headers = get_headers(@payload)
    puts @payload.to_json
    @result = HTTParty.post("#{@api_base}#{@api_path}", :body => @payload.to_json, :headers => headers )
    p @result
  end
end

disco = Disco.new('COVER_LETTER.md')
puts disco.post_payload
