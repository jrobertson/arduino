#!/usr/bin/env ruby

# A ruby library to talk to Arduino without 
# having to burn programs repeatedly to the board.
#
# Author::    Akash Manohar  (akash@akash.im)
# Copyright:: Copyright (c) 2010 Akash Manohar
# License::   MIT License

require "serialport"

# The main Arduino class.
# Allows managing connection to board and getting & setting pin states.

class Arduino

  # initialize port and baudrate
  def initialize(port, baudrate=115200)
    puts "initialized"
    data_bits = 8
    stop_bits = 1
    parity = SerialPort::NONE

    @serial = SerialPort.new port, baudrate
    @serial.read_timeout = 2
    @serial.sync

    @port = port
    @output_pins = []
    @pin_states = {}
  end

  # Print information about connected board
  def to_s
    "Arduino is on port #{@port} at #{@serial.baud} baudrate"
  end

  # Set output pins. This is a must.
  def output(*pin_list)
    send_data(pin_list.length)
    if pin_list.class==Array
      @output_pins = pin_list
      pin_list.each do |pin|
        send_pin(pin)
      end
    else
      raise ArgumentError, "Arguments must be a list of pin numbers"
    end
    puts "return pinlist"
    return pin_list
  end

  # Set a pin state to low
  def set_low(pin)
    save_state(pin, false)
    send_data('0')
    send_pin(pin)
  end

  def is_low?(pin)
    if !get_state(pin)
      return true
    else
      return false
    end
  end

  # Set a pin state to high
  def set_high(pin)
    save_state(pin, true)
    send_data('1')
    send_pin(pin)
  end

  def is_high?(pin)
    if get_state(pin)
      return true
    else
      return false
    end
  end

  def save_state(pin, state)
    @pin_states[pin.to_s] = state
  end

  # Get state of a digital pin. Returns true if high and false if low.
  def get_state(pin)
    if @pin_states.key?(pin.to_s)
      return @pin_states[pin.to_s]
    end
    return false
  end

  # Write to an analog pin
  def analog_write(pin, value)
    send_data('3')
    full_hex_value = value.to_s(base=16)
    hex_value = hex_value[2..full_hex_value.length]
    if(hex_value.length==1)
      send_data('0')
    else
      send_data(hex_value[0])
    end
    send_data(hex_value[1])
  end

  # Read from an analog pin
  def analog_read(pin)
    send_data('4')
    send_pin(pin)
    get_data()
  end

  # set all pins to low
  def turn_off
    @output_pins.each do |pin|
      set_low(pin)
    end
  end

  # close serial connection to connected board
  def close
    # stops executing arduino code
    @serial.write '5'.chr  
    # resets the arduino board (not on windows)   
    @serial.dtr=(0) 
    # close serial connection
    @serial.close
    p "closed"
  end

  private

  def send_pin(pin)
    pin_in_char = (pin+48)
    send_data(pin_in_char)
  end

  def send_data(serial_data)
    while true
      break if get_data()=="?"
    end
    s = String(serial_data.chr)
    x = @serial.write s
  end

  def get_data
    clean_data = @serial.readlines()
    clean_data = clean_data.join("").gsub("\n","").gsub("\r","")
  end
end
