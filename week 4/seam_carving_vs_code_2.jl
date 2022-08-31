import ImageMagick
using Images, TestImages, ImageFiltering
using Statistics
using BenchmarkTools

function remove_seam(img::Matrix, column_numbers::Vector)
        m, n = size(img)
        @assert m == length(column_numbers) # same as the number of rows
    
        local img_copy = similar(img, m, n-1) # create a similar image with one column less
    
        for (i, j) in enumerate(column_numbers)
            img_copy[i, 1:j-1] .= @view img[i, 1:(j-1)]
            img_copy[i, j:end] .= @view img[i, (j+1):end]
        end

        return img_copy
    end
#removes 1 pixel in each row

brightness(c::RGB) = mean((c.r, c.g, c.b))
brightness(c::RGBA) = mean((c.r, c.g, c.b))
brightness(c::Gray) = gray(c)
# turns a picture into a matrix of values

convolve(img, k) = imfilter(img, reflect(k)) # uses ImageFiltering.jl
# convolution with a kernel

float_to_color(x) = RGB(max(0, -x), max(0, x), max(0, x))
float_to_color(M::AbstractMatrix) = float_to_color.(M)
# visualizes the matrix, red negative value, cyan positive value

function energies(img)
	∇y = convolve(brightness.(img), Kernel.sobel()[1])
	∇x = convolve(brightness.(img), Kernel.sobel()[2])
	return sqrt.(∇x.^2 .+ ∇y.^2)
end
# edge detection but spits out a matrix

function least_energy_matrix(energies)
	min_energy_matrix = copy(energies)
	direction_matrix = zeros(size(energies))
	m, n = size(energies)

	min_energy_matrix[m, :] .= energies[m, :]
	
	for i in (m-1):(-1):1
		for j in 1:n
			j_min, j_max = max(1, j-1), min(j+1, n) # boundary conditions
			
			min_energy, direction = findmin(min_energy_matrix[i+1, j_min:j_max])
			
			min_energy_matrix[i, j] += energies[i, j] + min_energy
			direction_matrix[i, j] = (-1, 0, 1)[direction + (j==1)]
		end
	end
	
	return min_energy_matrix, direction_matrix
end 

function seam_from_direction(direction, starting_pixel::Int)
	m = size(direction, 1)
	column_index = fill(0, m)
	column_index[1] = starting_pixel
	
	for i in 2:m
		column_index[i] = column_index[i-1] + direction[i-1, column_index[i-1]]
	end

	return column_index
end

function cut_seam(img, n)
    new_imgs = []

    energy_matrix = energies(img)
    for i=1:n
		least_energy, direction = least_energy_matrix(energy_matrix)
		min_value, min_index = findmin(@view least_energy[1, :])
		seam = seam_from_direction(direction, min_index)

		img = remove_seam(img, seam)
		energy_matrix = remove_seam(energy_matrix, seam)

 		push!(new_imgs, img)
	end

    return new_imgs
end
# puts it all together


image_urls = [
    "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Hilma_af_Klint_-_Group_IX_SUW%2C_The_Swan_No._1_%2813947%29.jpg/477px-Hilma_af_Klint_-_Group_IX_SUW%2C_The_Swan_No._1_%2813947%29.jpg"
]
img_original = load(download(image_urls[1]))
img = copy(img_original)

new_imgs = cut_seam(img, 77)
new_imgs[77]