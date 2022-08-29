using ImageMagick
using Colors, ColorVectorSpace, ImageShow, FileIO, ImageIO
using ImageFiltering
using Plots

using Statistics, LinearAlgebra

image_urls = [
    "https://wisetoast.com/wp-content/uploads/2015/10/The-Persistence-of-Memory-salvador-deli-painting.jpg"
]

function edgeness(img)
	Sy, Sx = Kernel.sobel()
	b = brightness.(img)

	∇y = convolve(b, Sy)
	∇x = convolve(b, Sx)

	sqrt.(∇x.^2 + ∇y.^2)
end

function shrink_image(image, ratio=5)
	(height, width) = size(image)
	new_height = height ÷ ratio - 1
	new_width = width ÷ ratio - 1
	list = [
		mean(image[
			ratio * i:ratio * (i + 1),
			ratio * j:ratio * (j + 1),
		])
		for j in 1:new_width
		for i in 1:new_height
	]
	reshape(list, new_height, new_width)
end

function convolve(M, kernel)
    height, width = size(kernel)
    
    half_height = height ÷ 2
    half_width = width ÷ 2
    
    new_image = similar(M)
	
    m, n = size(M)

    # (i, j) loop over the original image
    @inbounds for i in 1:m
        for j in 1:n

			accumulator = 0 * M[1, 1]

            # (k, l) loop over the neighbouring pixels
			for k in -half_height:-half_height + height - 1
				for l in -half_width:-half_width + width - 1
					Mi = i - k
					Mj = j - l

					# First index into M
					if Mi < 1
						Mi = 1
					elseif Mi > m
						Mi = m
					end

					# Second index into M
					if Mj < 1
						Mj = 1
					elseif Mj > n
						Mj = n
					end
					
					accumulator += kernel[k, l] * M[Mi, Mj]
				end
			end

			new_image[i, j] = accumulator
        end
    end
    
    return new_image
end

function least_edgy(E)
	least_E = zeros(size(E))
	dirs = zeros(Int, size(E))
	
	least_E[end, :] .= E[end, :] # the minimum energy on the last row is the energy itself

	m, n = size(E)

    # Go from the last row up, finding the minimum energy
	for i in m-1:-1:1
		for j in 1:n

			j1, j2 = max(1, j-1), min(j+1, n)
			e, dir = findmin(least_E[i+1, j1:j2])
			least_E[i,j] += e
			least_E[i,j] += E[i,j]
			dirs[i, j] = (-1, 0, 1)[dir + (j==1)]
			
		end
	end
	
	return least_E, dirs
end

function get_seam_at(dirs, j)
	m = size(dirs, 1)
	js = fill(0, m)
	js[1] = j
	
	for i=2:m
		js[i] = js[i-1] + dirs[i-1, js[i-1]]
	end
	
	return tuple.(1:m, js)
end # spits out a tuple of indices of least ammount of importance

function mark_path(img, path)
	img′ = copy(img)
	m = size(img, 2)
	
	for (i, j) in path
		# To make it easier to see, we'll color not just
		# the pixels of the seam, but also those adjacent to it
		
		for j′ in j-1:j+1
			img′[i, clamp(j′, 1, m)] = RGB(1,0,1)
		end
		
	end
	
	return img′
end

function rm_path(img, path)
	img′ = img[:, 1:end-1] # one less column
	for (i, j) in path
		img′[i, 1:j-1] .= img[i, 1:j-1]
		img′[i, j:end] .= img[i, j+1:end]
	end
	img′
end

function shrink_n(img, n)
	imgs = []

	e = edgeness(img)
	for i=1:n
		least_E, dirs = least_edgy(e)
		_, min_j = findmin(@view least_E[1, :])
		seam = get_seam_at(dirs, min_j)
		img = rm_path(img, seam)
		# Recompute the energy for the new image
		# Note, this currently involves rerunning the convolution
		# on the whole image, but in principle the only values that
		# need recomputation are those adjacent to the seam, so there
		# is room for a meanintful speedup here.
    #		e = edgeness(img)
		e = rm_path(e, seam)

 		push!(imgs, img)
	end
    return imgs
end

#brightness(c::AbstractRGB) = 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
brightness(c::AbstractRGB) = mean(c.r + c.g + c.b) # turns image into matrix of numbers

image_url = image_urls[1]
img = load(download(image_url))


imgs = shrink_n(img, 200)
imgs[200]