defmodule GrovePi.Barometer.Calculator do
  @moduledoc """
  Transforms raw sensor data into temperature and pressure readings

  These are the calculations used to convert the raw temp and pressure data from the BMP280 Digital Pressure Sensor into usable values as specified in the datasheet.

  https://ae-bst.resource.bosch.com/media/_tech/media/datasheets/BST-BMP280-DS001-18.pdf
  """
  @type raw_temperature :: integer
  @type raw_pressure :: integer
  @type celcius :: float
  @type pascal :: float
  @type calibration_data
  :: %{
    dig_T1: non_neg_integer,
    dig_T2: integer,
    dig_T3: integer,
    dig_P1: non_neg_integer,
    dig_P1: integer,
    dig_P2: integer,
    dig_P3: integer,
    dig_P4: integer,
    dig_P5: integer,
    dig_P6: integer,
    dig_P7: integer,
    dig_P8: integer,
    dig_P9: integer,
  }

  @doc """
  Calculates temperature (celcius) and pressure (pascal)

  Inputs are raw values and calibration data retreived from the sensor.  Returns values with a precision of .01

  Sample test values taken from the data sheet (BST-BMP280-DS001-18 | Revision 1.18 | November 2016 section 3.11.3).

      iex> sample_calibrations = %{dig_T1: 27504,
      ...>                         dig_T2: 26435,
      ...>                         dig_T3: -1000,
      ...>                         dig_P1: 36477,
      ...>                         dig_P2: -10685,
      ...>                         dig_P3: 3024,
      ...>                         dig_P4: 2855,
      ...>                         dig_P5: 140,
      ...>                         dig_P6: -7,
      ...>                         dig_P7: 15500,
      ...>                         dig_P8: -14600,
      ...>                         dig_P9: 6000}
      ...>
      iex> GrovePi.Barometer.Calculator.calibrate(519_888, 415_148, sample_calibrations)
      { 25.08, 100_653.27 }
  """
  @spec calibrate(raw_temperature, raw_pressure, calibration_data) :: {celcius, pascal}
  def calibrate(raw_temperature, raw_pressure, calibration_data) do
    temperature = calibrate_temperature(raw_temperature, calibration_data)
    pressure = calibrate_pressure(temperature, raw_pressure, calibration_data)

    {Float.round(temperature, 2), Float.round(pressure, 2)}
  end

  defp calibrate_temperature(raw_temperature, calibration_data) do
    var1 = (raw_temperature/16384 - calibration_data.dig_T1/1024) * calibration_data.dig_T2
    var2 = (raw_temperature/131072 - calibration_data.dig_T1/8192) * (raw_temperature/131072 - calibration_data.dig_T1/8192) * calibration_data.dig_T3
    (var1 + var2) / 5120
  end

  defp calibrate_pressure(temperature, raw_pressure, calibration_data) do
    fine_temperature = temperature * 5120
    var1 = fine_temperature/2 - 64000
    var2 = var1 * var1 * calibration_data.dig_P6 / 32768
    var2 = var2 + var1 * calibration_data.dig_P5 * 2
    var2 = var2 / 4 + calibration_data.dig_P4 * 65536
    var1 = (calibration_data.dig_P3 * var1 * var1 / 524288 + calibration_data.dig_P2 * var1) / 524288
    var1 = (1 + var1/32768) * calibration_data.dig_P1
    p = 1048576 - raw_pressure
    p = (p - (var2/4096)) * 6250/var1
    var1 = calibration_data.dig_P9 * p * p / 2147483648
    var2 = p * calibration_data.dig_P8 / 32768
    pressure = p + (var1 + var2 + calibration_data.dig_P7) / 16
  end
end
