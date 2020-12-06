defmodule Eksel.CSV do
  @behaviour Saxy.Handler

  def parse(file_path) do
    {:ok, path} = Briefly.create(extname: ".csv")

    System.cmd("ssconvert", [file_path, "--recalc", "--export-type=Gnumeric_stf:stf_csv", path])

    parse_csv(path)
  end

  def parse_csv(file_path) do
    {_, rows} =
      file_path
      |> File.stream!()
      |> Stream.filter(&(&1 != "\n"))
      |> Stream.map(&fix_known_errors/1)
      |> NimbleCSV.RFC4180.parse_stream(skip_headers: false)
      |> Enum.reduce({0, []}, fn item, {num, acc} ->
        {_, cells} =
          Enum.reduce(item, {0, []}, fn item_col, {num_col, acc} ->
            {
              num_col + 1,
              [
                %{
                  row: num,
                  col: num_col,
                  value: item_col
                }
                | acc
              ]
            }
          end)

        {
          num + 1,
          [
            Enum.sort_by(cells, fn cell ->
              Map.get(cell, :col)
            end)
            | acc
          ]
        }
      end)

    {
      :ok,
      Enum.reverse(rows)
    }
  end

  def fix_known_errors(string) do
    string
    |> String.replace(" & ", " &amp; ")
    |> String.replace("&raquo;", "")
    |> String.replace("&quot;", "'")
  end

  def handle_event(:start_element, {"Cell", attributes}, {nil, cells}) do
    attributes = attributes |> Enum.into(%{})

    cell = %{
      row: String.to_integer(Map.get(attributes, "Row")),
      col: String.to_integer(Map.get(attributes, "Col")),
      value: nil
    }

    {:ok, {"Cell", [cell | cells]}}
  end

  def handle_event(:characters, chars, {"Cell", [cell | cells]}) do
    {:ok, {nil, [Map.put(cell, :value, chars) | cells]}}
  end

  def handle_event(:end_element, {"Cell", _}, {_, cells}) do
    {:ok, {nil, cells}}
  end

  ### Catch-all:s
  def handle_event(:characters, _chars, state), do: {:ok, state}

  def handle_event(:start_element, {_name, _attributes}, state) do
    {:ok, state}
  end

  def handle_event(:end_element, _name, state) do
    {:ok, state}
  end

  def handle_event(:start_document, _prolog, state) do
    {:ok, state}
  end

  def handle_event(:end_document, _data, {_, cells}) do
    cells
    |> Enum.sort_by(fn cell ->
      Map.get(cell, :col)
    end)
    |> Enum.group_by(fn cell ->
      Map.get(cell, :row)
    end)
    |> OK.wrap()
  end
end
