defmodule RC522 do
  use Bitwise
  alias Circuits.SPI

  @register %{
    command:       0x01,
    com_ien:       0x02,
    div_ien:       0x03,
    com_irq:       0x04,
    div_irq:       0x05,
    error:         0x06,
    status_1:      0x07,
    status_2:      0x08,
    fifo_data:     0x09,
    fifo_level:    0x0A,
    water_level:   0x0B,
    control:       0x0C,
    bit_framing:   0x0D,
    coll:          0x0E,

    mode:          0x11,
    tx_mode:       0x12,
    rx_mode:       0x13,
    tx_control:    0x14,
    tx_auto:       0x15,
    tx_sel:        0x16,
    rx_sel:        0x17,
    rx_threshold:  0x18,
    demod:         0x19,

    crc_result_h:  0x21,
    crc_result_l:  0x22,
    mod_width:     0x24,

    t_mode:        0x2A,
    t_prescaler:   0x2B,
    t_reload_h:    0x2C,
    t_reload_l:    0x2D
  }

  @pcd %{
    idle:          0x00,
    mem:           0x01,
    gen_rand_id:   0x02,
    calc_crc:      0x03,
    transmit:      0x04,
    no_cmd_change: 0x07,
    receive:       0x08,
    transceive:    0x0C,
    mifare_auth:   0x0E,
    soft_reset:    0x0F
  }

  @flag %{
    antenna_on: 0x03
  }

  def initialize(spi) do
    spi
    |> reset
    |> write(@register.tx_mode, 0x00)
    |> write(@register.rx_mode, 0x00)
    |> write(@register.mod_width, 0x26)
    |> write(@register.t_mode, 0x8D)
    |> write(@register.t_prescaler, 0x3E)
    |> write(@register.t_reload_l, 0x30)
    |> write(@register.t_reload_h, 0x00)
    |> write(@register.tx_auto, 0x40)
    |> write(@register.mode, 0x3D)
    |> antenna_on
  end

  def reset(spi) do
    write(spi, @register.command, @pcd.soft_reset)
    :timer.sleep(150)
    spi
  end

  def antenna_on(spi) do
    state = read(spi, @register.tx_control)
    if (state &&& @flag.antenna_on) != @flag.antenna_on do
      set_bit_bask(spi, @register.tx_control, @flag.antenna_on)
    end
    spi
  end

  def antenna_off(spi) do
    clear_bit_mask(spi, @register.tx_control, @flag.antenna_on)
  end

  def set_bit_bask(spi, register, mask) do
    state = read(spi, register)
    value = bor(state, mask)
    write(spi, register, <<value>>)
    spi
  end

  def clear_bit_mask(spi, register, mask) do
    state = read(spi, register)
    value = state &&& bnot(mask)
    write(spi, register, <<value>>)
  end

  def write(spi, register, value) do
    register = (register <<< 1) &&& 0x7E
    SPI.transfer(spi, <<register, value>>)
    spi
  end

  def read(spi, register) do
    register = bor(0x80, (register <<< 1) &&& 0x7E)
    {:ok, val} = SPI.transfer(spi, <<register, 0x00>>)
    val
  end
end
