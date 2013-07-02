# -*- ruby encoding: utf-8 -*-

# An HSL colour object. Internally, the hue (#h), saturation (#s), and
# luminosity/lightness (#l) values are dealt with as fractional values in
# the range 0..1.
class Color::HSL
  class << self
    # Creates an HSL colour object from fractional values 0..1.
    def from_fraction(h = 0.0, s = 0.0, l = 0.0)
      new(h, s, l, 1.0, 1.0)
    end
  end

  # Compares the other colour to this one. The other colour will be
  # converted to HSL before comparison, so the comparison between a HSL
  # colour and a non-HSL colour will be approximate and based on the other
  # colour's #to_hsl conversion. If there is no #to_hsl conversion, this
  # will raise an exception. This will report that two HSL values are
  # equivalent if all component values are within Color::COLOR_TOLERANCE of
  # each other.
  def ==(other)
    Color.equivalent?(self, other)
  end

  # Coerces the other Color object into HSL.
  def coerce(other)
    other.to_hsl
  end

  # Creates an HSL colour object from the standard values of degrees and
  # percentages (e.g., 145 deg, 30%, 50%).
  def initialize(h = 0, s = 0, l = 0, radix1 = 360.0, radix2 = 100.0)
    @h = h / radix1
    @s = s / radix2
    @l = l / radix2
  end

  # Present the colour as an HTML/CSS colour string.
  def html
    to_rgb.html
  end

  # Present the colour as an RGB HTML/CSS colour string (e.g., "rgb(0%, 50%,
  # 100%)"). Note that this will perform a #to_rgb operation using the
  # default conversion formula.
  def css_rgb
    to_rgb.css_rgb
  end

  # Present the colour as an RGBA (with alpha) HTML/CSS colour string (e.g.,
  # "rgb(0%, 50%, 100%, 1)"). Note that this will perform a #to_rgb
  # operation using the default conversion formula.
  def css_rgba
    to_rgb.css_rgba
  end

  # Present the colour as an HSL HTML/CSS colour string (e.g., "hsl(180,
  # 25%, 35%)").
  def css_hsl
    "hsl(%3.2f, %3.2f%%, %3.2f%%)" % [ hue, saturation, luminosity ]
  end

  # Present the colour as an HSLA (with alpha) HTML/CSS colour string (e.g.,
  # "hsla(180, 25%, 35%, 1)").
  def css_hsla
    "hsla(%3.2f, %3.2f%%, %3.2f%%, %3.2f)" % [ hue, saturation, luminosity, 1 ]
  end

  # Converting from HSL to RGB. As with all colour conversions, this is
  # approximate at best. The code here is adapted from Foley and van Dam,
  # originally found at [1] (implemented similarly at [2]), and a variation
  # at [3]. An additional variation has been found at [4].
  #
  # Since there are subtle differences between these algorithms, three of them
  # have been implemented:
  #
  # - The default is the standard Foley and van Dam, implemented as the only
  #   method in Color for the last few years. This can be explicitly called
  #   as :foley. I have tried to make the implemented code a little clearer
  #   to understand. This also includes three primary implementation
  #   simplifications:
  #   - Luminance values <= 0 always translate to Color::RGB::Black.
  #   - Luminance values >= 1 always translate to Color::RGB::White.
  #   - Saturation values <= 0 always translate to a shade of gray using
  #     luminance as a percentage of gray.
  # - The second variant can be called as :foley_alt
  # - The third variant can be called as :wikipedia, for lack of a better
  #   source name.
  #
  # [1] http://bobpowell.net/RGBHSB.aspx
  # [2] http://support.microsoft.com/kb/29240
  # [3] http://www5.informatik.tu-muenchen.de/lehre/vorlesungen/graphik/info/csc/COL_25.htm
  # [4] http://en.wikipedia.org/wiki/HSL_and_HSV#From_HSL
  def to_rgb(mode = :foley)
    Color::RGB.new(*send(:"to_rgb_#{mode}"))
  end

  # Converts to RGB then YIQ.
  def to_yiq
    to_rgb.to_yiq
  end

  # Converts to RGB then CMYK.
  def to_cmyk
    to_rgb.to_cmyk
  end

  # Returns the luminosity (#l) of the colour.
  def brightness
    @l
  end
  def to_greyscale
    Color::GrayScale.from_fraction(@l)
  end
  alias to_grayscale to_greyscale

  # Returns the hue of the colour in degrees.
  def hue
    @h * 360.0
  end
  # Returns the hue of the colour in the range 0.0 .. 1.0.
  def h
    @h
  end
  # Sets the hue of the colour in degrees. Colour is perceived as a wheel,
  # so values should be set properly even with negative degree values.
  def hue=(hh)
    hh = hh / 360.0

    hh += 1.0 if hh < 0.0
    hh -= 1.0 if hh > 1.0

    @h = Color.normalize(hh)
  end
  # Sets the hue of the colour in the range 0.0 .. 1.0.
  def h=(hh)
    @h = Color.normalize(hh)
  end
  # Returns the percentage of saturation of the colour.
  def saturation
    @s * 100.0
  end
  # Returns the saturation of the colour in the range 0.0 .. 1.0.
  def s
    @s
  end
  # Sets the percentage of saturation of the colour.
  def saturation=(ss)
    @s = Color.normalize(ss / 100.0)
  end
  # Sets the saturation of the colour in the ragne 0.0 .. 1.0.
  def s=(ss)
    @s = Color.normalize(ss)
  end

  # Returns the percentage of luminosity of the colour.
  def luminosity
    @l * 100.0
  end
  alias lightness luminosity
  # Returns the luminosity of the colour in the range 0.0 .. 1.0.
  def l
    @l
  end
  # Sets the percentage of luminosity of the colour.
  def luminosity=(ll)
    @l = Color.normalize(ll / 100.0)
  end
  alias lightness= luminosity= ;
  # Sets the luminosity of the colour in the ragne 0.0 .. 1.0.
  def l=(ll)
    @l = Color.normalize(ll)
  end

  def to_hsl
    self
  end

  def inspect
    "HSL [%.2f deg, %.2f%%, %.2f%%]" % [ hue, saturation, luminosity ]
  end

  # Mix the mask colour (which will be converted to an HSL colour) with the
  # current colour at the stated mix percentage as a decimal value.
  #
  # NOTE:: This differs from Color::RGB#mix_with.
  def mix_with(color, mix_percent = 0.5)
    v = to_a.zip(coerce(color).to_a).map { |(x, y)|
      ((y - x) * mix_percent) + x
    }
    self.class.from_fraction(*v)
  end

  def to_a
    [ h, s, l ]
  end

  private

  # Convert to an array that can be used with Color::RGB.new. As noted
  # above, luminances at the edges of luminance space map to all black or
  # all white, and zero saturation is black to gray. Only if we need more
  # specificity do we need to enter the main calculation.
  def to_rgb_foley
    if Color.near_zero_or_less?(l)
      [ 0, 0, 0, 1.0 ]
    elsif Color.near_one_or_more?(l)
      [ 1, 1, 1, 1.0 ]
    elsif Color.near_zero?(s)
      [ l, l, l, 1.0 ]
    else
      compute_foley_rgb + [ 1.0 ]
    end
  end

  # This algorithm calculates based on a mixture of the saturation and
  # luminance, and then takes the RGB values from the hue + 1/3, hue, and
  # hue - 1/3 positions in a circular representation of colour divided into
  # four parts (confusing, I know, but it's the way that it works). See
  # #hue_to_rgb for more information.
  def compute_foley_rgb
    t1, t2 = foley_mix_sat_lum
    [ h + (1 / 3.0), h, h - (1 / 3.0) ].map { |v|
      hue_to_rgb(rotate_hue(v), t1, t2)
    }
  end

  # Mix saturation and luminance for use in hue_to_rgb. The base value is
  # different depending on whether luminance is <= 50% or > 50%.
  def foley_mix_sat_lum
    t = if Color.near_zero_or_less?(l - 0.5)
             l * (1.0 + s.to_f)
           else
             l + s - (l * s.to_f)
           end
    [ 2.0 * l - t, t ]
  end
  #
  # In HSL, hues are referenced as degrees in a colour circle. The flow
  # itself is endless; therefore, we can rotate around. The only thing our
  # implementation restricts is that you should not be > 1.0.
  def rotate_hue(h)
    h += 1.0 if Color.near_zero_or_less?(h)
    h -= 1.0 if Color.near_one_or_more?(h)
    h
  end

  # We calculate the interaction of the saturation/luminance mix (calculated
  # earlier) based on the position of the hue in the circular colour space
  # divided into quadrants. Our hue range is [0, 1), not [0, 360º).
  #
  # - The first quadrant covers the first 60º [0, 60º].
  # - The second quadrant covers the next 120º (60º, 180º].
  # - The third quadrant covers the next 60º (180º, 240º].
  # - The fourth quadrant covers the final 120º (240º, 360º).
  def hue_to_rgb(h, t1, t2)
    if Color.near_zero_or_less?((6.0 * h) - 1.0)
      t1 + ((t2 - t1) * h * 6.0)
    elsif Color.near_zero_or_less?((2.0 * h) - 1.0)
      t2
    elsif Color.near_zero_or_less?((3.0 * h) - 2.0)
      t1 + (t2 - t1) * ((2 / 3.0) - h) * 6.0
    else
      t1
    end
  end
end
