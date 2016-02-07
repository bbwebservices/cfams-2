class Dash < ActiveRecord::Base
	# require 'open-uri'
	require 'net/http'
	require 'uri'
	belongs_to :user
	has_many :posts	

	def giphy_scrape(search)
		begin
			search = search ? search : self.giphy_search
			sanitize = search.tr(" ", "+");
			key = "dc6zaTOxFJmzC"
			url = "http://api.giphy.com/v1/gifs/search?q=" + sanitize + "&api_key=" + key
			resp = Net::HTTP.get_response(URI.parse(url))
			buffer = resp.body
			result = JSON.parse(buffer)
			puts "results: ", result['data']
			temp = []
			result['data'].each do |x|
				puts x
				temp.push(x["images"]["fixed_height"]["url"])
			end	
			temp.each do |post|
				self.build_post("giphy", post, post, post, post)
			end
			return temp 
		rescue
			return nil
		end
	end


	def reddit_pic_scrape(sub)
		subredd = sub ? sub : self.subreddit
		reddit_api_url = "https://www.reddit.com/r/"+ subredd +".json"
		resp = Net::HTTP.get_response(URI.parse(reddit_api_url))
		data = resp.body
		result = JSON.parse(data)
		temp = []
		result["data"]["children"].each do |post|
			begin
				temp.push([post["data"]["preview"]["images"].first["source"], post["data"]["title"]])
			rescue
				puts "nope"
			end
		end
		temp.each do |post|
			self.build_post("reddit", post[0]["url"], post[1], post[0]["url"], post[0])
		end

		return temp
	end	

	def twitter_pic_scrape(search)
		t = self.get_twit_client
		temp = []
		search_var = search
		t.search(search_var, result_type: "recent").collect do |tweet|
			unless tweet.media[0].nil?
				img = tweet.media[0].media_url
				puts img
				puts tweet.text
				temp.push(tweet.text, img)
				self.build_post("Twitter", img, tweet.text, img, img)
			end
		end	 		
	end

	def tumblr_pic_scrape(search)
		# self.get_tumblr_client
		client = Tumblr::Client.new
		search_var = search
		temp = []
		img = client.posts(search_var + ".tumblr.com", :type => "photo", :limit => 50)["posts"]
			# begin
			# 	puts "tried.."
			# 	# puts post
			# 	puts "other side of post = = = = = = ="
			# 	# img = post["posts"][0]["photos"][0]["alt_sizes"][0]["url"]
			# 	# temp.push(post)
			# rescue
			# 	puts "this one didn't work"
			# end
		# end
		puts "img:"
		# puts img

		img.each do |post|
			puts ">>>>>>>>>>>>>>>>>"
			extracted_img = post['photos'][0]['alt_sizes'][0]['url']
			puts extracted_img
			self.build_post("Tumblr", extracted_img, extracted_img, extracted_img, extracted_img)
			temp.push(extracted_img)
		end
	end

	# Auth Methods
	def get_twit_client
		twitCli = Twitter::REST::Client.new do |config|
		  config.consumer_key        = self.twit_consumer_key
		  config.consumer_secret     = self.twit_consumer_secret
		  config.access_token        = self.twit_access_token
		  config.access_token_secret = self.twit_access_token_secret
		end
		return twitCli
	end


	def get_tumblr_client
		@tumblr = Tumblr.configure do |config|
			  config.consumer_key = "4G9UxKrtral15WhmBZOw7qinXgcTm3zh6rpGA2VFP2pLYKuE2J"
			  config.consumer_secret = "kAjrMLb13wV3mDANN831KnthQFUZ9MtpbrUfIFlcLv9D0QkfRt"
			  config.oauth_token = "mm03apLTip6tllkxoUYSywJIXguY7MfxcMfjoWW32E53X0JMFk"
			  config.oauth_token_secret = "AYqbvri2JClz2D5YlRCvu6uAOMwnRq1fZur5TAxkCL0LQqHlUP"
			end
		return @tumblr
	end



	#Build Posts
	def build_post(title, src, body, image, author)
		p = self.posts.build(title: title, og_source: src, body: body, image_src: image)		
		p.save
	end




	# JSON Formatting
	# def as_json(options={})
	#   super(:only => [:name],
	#         :include => {
	#           :posts => {:only => [:title, :body, :image_src]
	#           }
	#         }
	#   )
	# end	
end


