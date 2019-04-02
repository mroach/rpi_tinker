defmodule RC522 do
  use Bitwise
  require Logger
  alias Circuits.SPI
  alias Circuits.GPIO

  # MFRC522 docs 9.2 "Register Overview"
  @register %{
    command:       0x01,
    comm_ien:      0x02,  # toggle interrupt request control bits
    div_ien:       0x03,  # toggle interrupt request control bits
    comm_irq:      0x04,  # interrupt request bits
    div_irq:       0x05,  # interrupt request bits
    error:         0x06,  # error status of last command executed
    status_1:      0x07,  # communication status bits
    status_2:      0x08,  # receiver and transmitter status bits
    fifo_data:     0x09,  # 64 byte FIFO buffer
    fifo_level:    0x0A,  # number of bytes stored in the FIFO register
    water_level:   0x0B,  # level for FIFO under/overflow warning
    control:       0x0C,  # miscellaneous control registers
    bit_framing:   0x0D,
    coll:          0x0E,

    mode:          0x11,  # general mode for transmit and receive
    tx_mode:       0x12,  # transmission data rate and framing
    rx_mode:       0x13,  # reception data rate and framing
    tx_control:    0x14,  # control logical behaviour of the antenna TX1 and TX2 pins
    tx_auto:       0x15,  # control setting of transmission moduleation
    tx_sel:        0x16,  # select internal sources for the antenna driver
    rx_sel:        0x17,  # receiver settings
    rx_threshold:  0x18,  # thresholds for bit decoder
    demod:         0x19,  # demodulator settings

    crc_result_h:  0x21,  # show the MSB and LSB values of the CRC calculation
    crc_result_l:  0x22,  # show the MSB and LSB values of the CRC calculation
    mod_width:     0x24,

    t_mode:        0x2A,  # define settings for the internal timer
    t_prescaler:   0x2B,  # define settings for the internal timer
    t_reload_h:    0x2C,  # define the 16-bit timer reload value
    t_reload_l:    0x2D,

    version:       0x37   # show software version
  }
  @valid_registers Map.values(@register)

  # MFRC522 documentation 10.3 "Command overview"
  # Use with the "command" register
  @command %{
    idle:          0x00,  # no action, cancels current command execution
    mem:           0x01,  # stores 25 bytes into the internal buffer
    gen_rand_id:   0x02,  # generates a 10-byte random ID number
    calc_crc:      0x03,  # activates the CRC coprocessor or performs a self test
    transmit:      0x04,  # transmits data from the FIFO buffer
    no_cmd_change: 0x07,  # can be used to modify the command register bits without affecting the command
    receive:       0x08,  # activates the receiver circuits
    transceive:    0x0C,  # transmits data from the FIFO buffer to antenna and automatically activates the receiver after transmission
    mifare_auth:   0x0E,  # perform standard MIFARE auth as a reader
    soft_reset:    0x0F   # perform a soft reset
  }

  @picc %{
    request_idl:  0x26,
    request_all:  0x52,
    anticoll:     0x93
  }

  # 9.3.2.5 Transmission control
  @tx_control %{
    antenna_on: 0x03
  }

  @gpio_reset_pin 25

  def initialize(spi) do
    spi
    |> reset
    #|> write(@register.tx_mode, 0x00)
    #|> write(@register.rx_mode, 0x00)
    #|> write(@register.mod_width, 0x26)
    |> write(@register.t_mode, 0x8D)
    |> write(@register.t_prescaler, 0x3E)
    |> write(@register.t_reload_l, 0x30)
    |> write(@register.t_reload_h, 0x00)
    |> write(@register.tx_auto, 0x40)
    |> write(@register.mode, 0x3D)
    |> antenna_on

    hwver = hardware_version(spi)
    Logger.info "Found #{hwver.chip_type} version #{hwver.version}"
  end

  @doc """
  See MFRC522 docs 9.3.4.8
  Bits 7 to 4 are the chiptype. Should always be "9" for MFRC522
  Bits 0 to 3 are the version
  """
  def hardware_version(spi) do
    <<_, data>> = read(spi, @register.version)
    %{
      chip_type: chip_type((data &&& 0xF0) >>> 4),
      version: data &&& 0x0F
    }
  end

  defp chip_type(9), do: :mfrc522
  defp chip_type(type), do: "unknown_#{ type }"

  def read_id(spi) do
    request(spi, @picc.request_idl)
    #anticoll
  end

  def request(spi, what) do
    write(spi, @register.bit_framing, 0x07)
    to_card(spi, @command.transceive, what)
  end

  def to_card(spi, command, data) do
    # THESE ARE ONLY FOR COMMAND == transceive
    irq_en = 0x77
    wait_irq = 0x30

    spi
    |> write(@register.comm_ien, bor(0x80, irq_en))
    |> clear_bit_mask(@register.comm_irq, 0x80)
    |> set_bit_bask(@register.fifo_level, 0x80)
    |> write(@register.command, @command.idle)
    |> write(@register.fifo_data, data)
    |> write(@register.command, command)

    if command == @command.transceive do
      set_bit_bask(spi, @register.bit_framing, 0x80)
    end

    #clear_bit_mask(spi, @register.bit_framing, 0x80)
  end

  def reset(spi) do
    {:ok, gpio} = GPIO.open(@gpio_reset_pin, :output)
    GPIO.write(gpio, 1)

    write(spi, @register.command, @command.soft_reset)
    :timer.sleep(150)
    spi
  end

  def last_error(spi) do
    <<_, err>> = read(spi, @register.error)
    err &&& 0x1B
  end

  def read_fifo(spi) do
    <<_, level>> = read(spi, @register.fifo_level)
    <<_, last_bits>> = read(spi, @register.control) &&& 0x07
    back_len = case last_bits do
      0 -> level * 8
      n -> (n - 1) * 8 + last_bits
    end


  end

  def antenna_on(spi) do
    <<_, state>> = read(spi, @register.tx_control)
    if (state &&& @tx_control.antenna_on) != @tx_control.antenna_on do
      set_bit_bask(spi, @register.tx_control, @tx_control.antenna_on)
    end
    spi
  end

  def antenna_off(spi) do
    clear_bit_mask(spi, @register.tx_control, @tx_control.antenna_on)
  end

  def set_bit_bask(spi, register, mask) when register in @valid_registers do
    <<_, state>> = read(spi, register)
    value = bor(state, mask)
    write(spi, register, value)
  end

  def clear_bit_mask(spi, register, mask) when register in @valid_registers do
    <<_, state>> = read(spi, register)
    value = state &&& bnot(mask)
    write(spi, register, value)
  end

  def write(spi, register, value) when register in @valid_registers do
    register = (register <<< 1) &&& 0x7E
    SPI.transfer(spi, <<register, value>>)
    spi
  end

  def read(spi, register) when register in @valid_registers do
    register = bor(0x80, (register <<< 1) &&& 0x7E)
    {:ok, val} = SPI.transfer(spi, <<register, 0x00>>)
    val
  end
end
