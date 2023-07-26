extends Node

class TIM:
	var magic
	var version
	var flag
	var bpp
	var has_clut
	
	var clut_data = null
	var pixel_data = null
	
	func read(f : FileAccess):
		self.magic = f.get_8()
		if self.magic != 0x10:
			printerr("TIM ERROR: Magic is not 0x10!")
			#return FAILED
		
		self.version = f.get_8()
		assert(self.version == 0x0)
		
		var dummy = f.get_16()
		
		flag = f.get_8()
		self.bpp = flag & 0b0011
		self.has_clut = flag & 0b1000 != 0
		
		# Dummy
		f.get_16()
		f.get_8()
		
		#print("-- BPP MODE: ", self.bpp)
		#print("-- HAS CLUT: ", self.has_clut)
		
		if has_clut:
			self.clut_data = DataBlock.new()
			self.clut_data.read(f)
		
		self.pixel_data = DataBlock.new()
		self.pixel_data.read(f)
		
		return OK
	
	func process_clut_colour(clut_index, clut_stream : StreamPeerBuffer, pixel_stream : StreamPeerBuffer, process_transparency = false):
		var index = pixel_stream.get_u8()
		
		var rgba = []
		if self.bpp == 0:
			index = [index & 0x0F, index >> 4]
			clut_index = clut_index * 16
		else:
			index = [index]
			clut_index = clut_index * 256
		
		for i in index:
			clut_stream.seek((i*2) + clut_index)
			var packed_colour = clut_stream.get_u16()
			var stb = packed_colour >> 15 & 1
			var alpha = 0 if process_transparency and stb == 1 else 255
			rgba.append_array([(packed_colour & 0x1F) * 8, (packed_colour >> 5 & 0x1F) * 8, (packed_colour >> 10 & 0x1F) * 8, alpha])

		return rgba
		
	func process_16bpp(pixel_stream : StreamPeerBuffer, process_transparency = false):
		var packed_colour = pixel_stream.get_u16()
		var stb = packed_colour >> 15 & 1
		var alpha = 0 if process_transparency and stb == 1 else 255
		return [(packed_colour & 0x1F) * 8, (packed_colour >> 5 & 0x1F) * 8, (packed_colour >> 10 & 0x1F) * 8, alpha]

	func process_24bpp(pixel_stream : StreamPeerBuffer):
		return []
		
	func create_texture(clut_index = 0, process_transparency = false):
		if self.has_clut and clut_index > self.clut_data.height - 1:
			printerr("Palette Index does not exist: ", clut_index)
			return FAILED

		var clut_stream = StreamPeerBuffer.new()
		var pixel_stream = StreamPeerBuffer.new()
		pixel_stream.data_array = self.pixel_data.data
		if has_clut:
			clut_stream.data_array = self.clut_data.data
			
		var pixel_data = []
		
		var multiplier = 1
		if has_clut:
			if bpp == 1:
				multiplier = 2
			elif bpp == 0:
				multiplier = 4
				
		# We process clut indicies as u8 instead of reading in u16s
		var byte_length = 2 if self.has_clut else 1
		
		for y in range(self.pixel_data.height):
			for x in range(self.pixel_data.width * byte_length):
				if has_clut:
					var rgba = self.process_clut_colour(clut_index, clut_stream, pixel_stream, process_transparency)
					pixel_data.append_array(rgba)
				elif self.bpp == 2:
					var rgba = process_16bpp(pixel_stream, process_transparency)
					pixel_data.append_array(rgba)
				elif self.bpp == 3:
					printerr("Please open a github ticket with the image attached, as I can't find any examples of this format. Thanks!")
					break
				#	var rgba = process_24bpp(pixel_stream)
				#	pixel_data.append_array(rgba)
				else:
					printerr("Not implemented... : ", self.bpp)
					break
					
		
		
		# Create the texture
		var image = Image.create_from_data(self.pixel_data.width * multiplier, self.pixel_data.height, false, Image.FORMAT_RGBA8, pixel_data)
		var texture = ImageTexture.create_from_image(image)
		
		return texture
	
	class DataBlock:
		var size
		var x
		var y
		var width
		var height
		var data
		
		func read(f: FileAccess, cautious_read = false):
			self.size = f.get_32()
			self.x = f.get_16()
			self.y = f.get_16()
			self.width = f.get_16()
			self.height = f.get_16()
			
			self.data = f.get_buffer(self.width * self.height * 2)
			
			#print(','.join([self.size, self.x, self.y, self.width, self.height]))
			
