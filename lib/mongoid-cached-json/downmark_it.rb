# encoding: utf-8
# =Overview
# DownmarkIt is a library to convert HTML to markdown, based on Hpricot[http://github.com/hpricot/hpricot/].
#
# =Motivation
# While working on our company's new CMS, I needed to parse HTML back to markdown and surprisngly there wasn't any solution that could fit our enviroment, so I decided to make my own and share it :)
#
# =Usage
# Make sure you install Hpricot[http://github.com/hpricot/hpricot/] first, then require the library in your application, if you are using the library in a rails application, just place it in your lib folder, then use this method to convert HTML into markdown.
#  markdown = DownmarkIt.to_markdown(html)
#
# =Features
# This library supports variable header tags, horizontal rulers, emphasis, strong, links, images, blockquotes, code, unordered lists(nested) and ordered lists(nested)
#
# =WARNING
# Currently DownmarkIt does not support ul tags inside ol tags or vice versa, maybe in the future i will add it ;)
#
# =License
# This code is licensed under MIT License
require 'hpricot'

module Mongoid
  module CachedJson
    module DownmarkIt
    	# TODO: Add nested unordered lists inside ordered list and vice versa support
    	def self.to_markdown(html)
    		raw = Hpricot(html.gsub(/(\n|\r|\t)/, ""))
    		
    		# headers
    		(raw/"/<h\d>/").each do |header|
    			if(header.name.match(/^h\d$/))
    				header_level = header.name.match(/\d/).to_s.to_i
    				header.swap("#{"#" * header_level} #{header.inner_html}\r\n")
    			end
    		end
    		
    		# horizontal rulers
    		(raw/"hr").each do |hruler|
    			hruler.swap("\r\n---\r\n")
    		end
    		
    		# emphasis
    		(raw/"em").each do |em|
    			if(em.name == "em")
    				em.swap("_#{em.inner_html}_")
    			end
    		end
    		
    		# strong
    		(raw/"strong").each do |strong|
    			if(strong.name == "strong")
    				strong.swap("**#{strong.inner_html}**")
    			end
    		end
    		
    		# links (anchors)
    		(raw/"a").each do |anchor|
    			if(anchor.name=="a")
    				if(anchor.inner_html != "")
    					anchor.swap("[#{anchor.inner_html}](#{anchor['href']}#{" \"#{anchor['title']}\"" if anchor['title']})")
    				else
    					anchor.swap("<#{anchor['href']}>")
    				end
    			end
    		end
    		
    		# image
    		(raw/"img").each do |image|
    			image.swap("![#{image['alt']}](#{image['src']}#{" \"#{image['title']}\"" if image['title']})")
    		end
    		
    		# blockquote
    		(raw/"blockquote").each do |qoute|
    			if qoute.name == "blockquote"
    				qoute.swap("> #{nested_qoute(qoute)}")
    			end
    		end
    		
    		# code
    		(raw/"code").each do |code|
    			if code.name == "code"
    				code.swap("``#{code.inner_html}``")
    			end
    		end
    		
    		# unordered list
    		(raw/"ul").each do |ul|
    			if ul.name == "ul"
    				(ul/">li").each do |li|
    					if li.name == "li"
    						nli = nested_ul(li, 0)
    						if (nli.match(/ - /))
    							li_inner = (li.inner_text.match(/^\r\n/))?("#{li.inner_text.gsub(/^\r\n/, "")}\r\n"):("- #{li.inner_text}\r\n")
    							li.swap("#{li_inner}")
    						else
    							li.swap("- #{nli}\r\n")
    						end
    					end
    				end
    				ul.swap("#{ul.inner_html}")
    			end
    		end
    		
    		# ordered list
    		(raw/"ol").each do |ol|
    			if ol.name == "ol"
    				level = 0
    				(ol/">li").each do |li|
    					if li.name == "li"
    						nli = nested_ol(li, 0)
    						if (nli.match(/ \d+\. /))
    							li_inner = (li.inner_text.match(/^\r\n/))?("#{li.inner_text.gsub(/^\r\n/, "")}\r\n"):("#{level+=1}. #{li.inner_text}\r\n")
    							li.swap("#{li_inner}")
    						else
    							li.swap("#{level+=1}. #{nli}\r\n")
    						end
    					end
    				end
    				ol.swap("#{ol.inner_html}")
    			end
    		end
    
    		# lines
    		(raw /"p").each do |p|
    			if p.name == "p"
    				p.swap("\r\n#{p.inner_text}\r\n")
    			end
    		end
    		
    		return raw.to_s
    	end
    	
    	private
    	def self.nested_qoute(qoute)
    		nqoute = qoute.at("blockquote")
    		unless(nqoute.nil?)
    			nnqoute = nested_qoute(nqoute)
    			"> #{nnqoute}"
    		else
    			qoute.inner_html
    		end
    	end
    	
    	def self.nested_ul(li, level)
    		ul = li.at("ul")
    		unless(ul.nil?)
    			nested_uli(ul, level + 1)
    		else
    			li.inner_html
    		end
    	end
    	
    	def self.nested_uli(li, level)
    		nli = li.at("li")
    		unless(nli.nil?)
    			(li/">li").each do |cnli|
    				nnli = nested_ul(cnli, level + 1)
    				if (nnli.match(/ - /))
    					inner_li = (cnli.inner_text.match(/^\r\n/))?(""):(cnli.inner_text)
    					cnli.swap "\r\n#{" " * level}- #{inner_li}" unless inner_li == ""
    				else
    					cnli.swap "\r\n#{" " * level}- #{nnli}"
    				end
    			end
    			li.inner_html
    		else
    			li.inner_html
    		end
    	end
    	
    	def self.nested_ol(li, level)
    		ol = li.at("ol")
    		unless(ol.nil?)
    			nested_oli(ol, level + 1)
    		else
    			li.inner_html
    		end
    	end
    	
    	def self.nested_oli(li, level)
    		nli = li.at("li")
    		unless(nli.nil?)
    			nlevel = 0
    			(li/">li").each do |cnli|
    				nnli = nested_ol(cnli, level + 1)
    				if (nnli.match(/ \d+. /))
    					inner_li = (cnli.inner_text.match(/^\r\n/))?(""):(cnli.inner_text)
    					cnli.swap "\r\n#{" " * level}#{nlevel+=1}. #{inner_li}" unless inner_li == ""
    				else
    					cnli.swap "\r\n#{" " * level}#{nlevel+=1}. #{nnli}"
    				end
    			end
    			li.inner_html
    		else
    			li.inner_html
    		end
    	end
    end
  end
end
