require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class TestUrl < Minitest::Test
  context "a new Bitly::Url" do
    should "require a login and api_key" do
      assert_raises ArgumentError do Bitly::Url.new end
      assert_raises ArgumentError do Bitly::Url.new(login) end
      assert_raises ArgumentError do Bitly::Url.new(nil, api_key) end
    end
    context "shortening" do
      context "with a long url" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/shorten\?.*longUrl=.*cnn.com.*$/,"cnn.json")
          @url = Bitly::Url.new(login, api_key, :long_url => 'http://cnn.com/')
        end
        should "return a short url" do
          assert_equal "http://bit.ly/15DlK", @url.shorten
        end
        should "create bitly and jmp urls" do
          @url.shorten
          assert_equal "http://bit.ly/15DlK", @url.bitly_url
          assert_equal "http://j.mp/15DlK", @url.jmp_url
        end
      end
      context "with no long url" do
        setup do
          @url = Bitly::Url.new(login, api_key)
        end
        should "raise an error" do
          assert_raises ArgumentError do
            @url.shorten
          end
        end
      end
      context "with a short url already" do
        setup do
          @url = Bitly::Url.new(login, api_key, :short_url => 'http://bit.ly/31IqMl')
          flexmock(@url).should_receive(:create_url).never
        end
        should "not need to call the api" do
          assert_equal "http://bit.ly/31IqMl", @url.shorten
        end
      end
    end
    context "expanding" do
      context "with a hash" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/expand\?.*hash=31IqMl.*$/,"expand_cnn.json")
          @url = Bitly::Url.new(login, api_key, :hash => '31IqMl')
        end
        should "return an expanded url" do
          assert_equal "http://cnn.com/", @url.expand
        end
      end
      context "with a short url" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/expand\?.*hash=31IqMl.*$/,"expand_cnn.json")
          @url = Bitly::Url.new(login, api_key, :short_url => 'http://bit.ly/31IqMl')
        end
        should "return an expanded url" do
          assert_equal "http://cnn.com/", @url.expand
        end
      end
      context "with no short url or hash" do
        setup do
          @url = Bitly::Url.new(login, api_key)
        end
        should "raise an error" do
          assert_raises ArgumentError do
            @url.expand
          end
        end
      end
      context "with a long url already" do
        setup do
          @url = Bitly::Url.new(login, api_key, :long_url => 'http://google.com')
          flexmock(@url).should_receive(:create_url).never
        end
        should "not need to call the api" do
          assert_equal "http://google.com", @url.expand
        end
      end
    end
    context "info" do
      context "with a hash" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/info\?.*hash=3j4ir4.*$/,"google_info.json")
          @url = Bitly::Url.new(login, api_key, :hash => '3j4ir4')
        end
        should "return info" do
          assert_equal "Google", @url.info['htmlTitle']
        end
      end
      context "with a short url" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/info\?.*hash=3j4ir4.*$/,"google_info.json")
          @url = Bitly::Url.new(login, api_key, :short_url => 'http://bit.ly/3j4ir4')
        end
        should "return an expanded url" do
          assert_equal "Google", @url.info['htmlTitle']
        end
      end
      context "without a short url or hash" do
        setup do
          @url = Bitly::Url.new(login, api_key, :long_url => 'http://google.com')
        end
        should "raise an error" do
          assert_raises ArgumentError do
            @url.info
          end
        end
      end
      context "with info already" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/info\?.*hash=3j4ir4.*$/,"google_info.json")
          @url = Bitly::Url.new(login, api_key, :short_url => 'http://bit.ly/3j4ir4')
          @url.info
        end
        should "not call the api twice" do
          flexmock(@url).should_receive(:create_url).never
          @url.info
        end
      end
    end
    context "stats" do
      context "with a hash" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/stats\?.*hash=3j4ir4.*$/,"google_stats.json")
          @url = Bitly::Url.new(login, api_key, :hash => '3j4ir4')
        end
        should "return info" do
          assert_equal 2644, @url.stats['clicks']
        end
      end
      context "with a short url" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/stats\?.*hash=3j4ir4.*$/,"google_stats.json")
          @url = Bitly::Url.new(login, api_key, :short_url => 'http://bit.ly/3j4ir4')
        end
        should "return an expanded url" do
          assert_equal 2644, @url.stats['clicks']
        end
      end
      context "without a short url or hash" do
        setup do
          @url = Bitly::Url.new(login, api_key, :long_url => 'http://google.com')
        end
        should "raise an error" do
          assert_raises ArgumentError do
            @url.stats
          end
        end
      end
      context "with info already" do
        setup do
          stub_get(/^https:\/\/api-ssl\.bitly\.com\/stats\?.*hash=3j4ir4.*$/,"google_stats.json")
          @url = Bitly::Url.new(login, api_key, :short_url => 'http://bit.ly/3j4ir4')
          @url.stats
        end
        should "not call the api twice" do
          flexmock(@url).should_receive(:create_url).never
          @url.stats
        end
      end
    end

    context 'clicks' do
      context "with a hash" do
        setup do
          @client = Bitly::V4::Client.new(login, api_key)

          stub_request(:post, "https://api-ssl.bitly.com/v4/shorten").
            with(stubbed_headers).
            to_return(status: 200, body: '{"long_url": "https://google.com/", "link": "http://bit.ly/39graKZ", "id": "bit.ly/39graKZ"}')

          stub_request(:get, "https://api-ssl.bitly.com/v4/bitlinks/bit.ly/39graKZ/clicks/summary").
            with(stubbed_headers).
            to_return(status: 200, body: '{"unit_reference": "2020-02-24T15:41:13+0000","total_clicks": 1,"units": 30,"unit": ""}')

          stub_request(:get, "https://api-ssl.bitly.com/v4/bitlinks/bit.ly/39graKZ/clicks").
            with(stubbed_headers).
            to_return(status: 200, body: '{"unit_reference": "2020-02-24T15:41:13+0000","link_clicks": [{"date": "2020-02-26T00:00:00+0000","clicks": 0 } ] }')
        end

        should "return shortened url" do
          shorten = @client.shorten('https://google.com')

          expected_hash = { short_url: "http://bit.ly/39graKZ", long_url: "https://google.com/", user_clicks: nil }
          assert_equal  expected_hash, shorten.results
        end

        should "return clicks" do
          clicks = @client.clicks('bit.ly/39graKZ')

          expected_hash = { short_url: "bit.ly/39graKZ", long_url: nil, user_clicks: nil }
          assert_equal  expected_hash, clicks.results
        end

        should "return clicks summary" do
          clicks_summary = @client.clicks_summary('bit.ly/39graKZ')

          expected_hash = { short_url: 'bit.ly/39graKZ', long_url: nil, user_clicks: 1 }
          assert_equal  expected_hash, clicks_summary.results
        end

        should "return clicks summary when passing a url" do
          clicks_summary = @client.clicks_summary('https://bit.ly/39graKZ')

          expected_hash = { short_url: 'https://bit.ly/39graKZ', long_url: nil, user_clicks: 1 }
          assert_equal  expected_hash, clicks_summary.results
        end
      end
    end
  end

  private

  def stubbed_headers
    {
      headers: {
                'Authorization'=>'Bearer test_account',
                'Content-Type'=>'application/json',
                'Expect'=>'',
                'User-Agent'=>'Typhoeus - https://github.com/typhoeus/typhoeus'
              }
    }
  end
end
