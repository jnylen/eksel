defmodule Eksel do
  @moduledoc """
  Documentation for `Eksel`.
  """

  defdelegate parse_excel(file_path), to: Eksel.Excel, as: :parse
  # defdelegate parse_csv(file_path), to: Eksel.CSV, as: :parse
end
