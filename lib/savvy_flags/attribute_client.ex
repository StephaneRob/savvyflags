defmodule SavvyFlags.AttributeClient do
  alias SavvyFlags.Attributes.Attribute

  def request(url, access_token, value) do
    url = url <> "?q=#{value}"

    case Req.get(url, headers: headers(access_token)) do
      {:ok, %Req.Response{body: body}} -> body
      {_, error} -> error
    end
  end

  def headers(access_token) when access_token in ["", nil] do
    base_headers() ++ []
  end

  def headers(access_token) do
    base_headers() ++
      [
        {"Authorization", "Bearer #{access_token}"}
      ]
  end

  def base_headers do
    [{"Content-Type", "application/json"}]
  end

  def request(attribute, value) do
    %Attribute{url: url, access_token: access_token} = attribute
    request(url, access_token, value)
  end
end
