defmodule Eksel.Excel do
  @behaviour Saxy.Handler

  def parse(file_path) do
    {:ok, path} = Briefly.create(extname: ".xml")

    System.cmd("ssconvert", [file_path, "--recalc", "--export-type=Gnumeric_XmlIO:sax:0", path])

    parse_xml(path)
  end

  def parse_xml(file_path) do
    file_path
    |> File.stream!()
    |> Stream.filter(&(&1 != "\n"))
    |> Stream.map(&Helper.fix_known_errors/1)
    |> Saxy.parse_stream(__MODULE__, {nil, []})
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
    List.first(cells) |> IO.inspect()

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
