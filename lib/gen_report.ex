defmodule GenReport do
  alias GenReport.Parser

  @names [
    "cleiton",
    "daniele",
    "danilo",
    "diego",
    "giuliano",
    "jakeliny",
    "joseph",
    "mayk",
    "rafael",
    "vinicius"
  ]

  @months [
    "janeiro",
    "fevereiro",
    "março",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro"
  ]

  def build(), do: {:error, "Please provide a file name"}

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, acc -> sum(line, acc) end)
  end

  def build_from_many() do
    {:error, "Please provide a list of strings"}
  end

  def build_from_many(filenames) when not is_list(filenames) do
    {:error, "Please provide a list of strings"}
  end

  def build_from_many(filenames) do
    filenames
    |> Task.async_stream(&build/1)
    |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)
  end

  defp sum_reports(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    all_hours = merge_maps(all_hours1, all_hours2)
    hours_per_month = merge_maps(hours_per_month1, hours_per_month2)
    hours_per_year = merge_maps(hours_per_year1, hours_per_year2)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, &merge_values/3)
  end

  defp merge_values(_key, value1, value2) when is_map(value1) do
    merge_maps(value1, value2)
  end

  defp merge_values(_key, value1, value2) do
    value1 + value2
  end

  defp sum([name, hours, _day, month, year], %{
         "all_hours" => all_hours,
         "hours_per_month" => hours_per_month,
         "hours_per_year" => hours_per_year
       }) do
    all_hours = Map.put(all_hours, name, all_hours[name] + hours)

    hours_per_month = sum_monthly_hours(hours_per_month, name, month, hours)

    hours_per_year = sum_yearly_hours(hours_per_year, name, year, hours)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp sum_monthly_hours(hours_per_month, name, month, hours) do
    months_map = hours_per_month[name]
    months_map = Map.put(months_map, month, months_map[month] + hours)
    Map.put(hours_per_month, name, months_map)
  end

  defp sum_yearly_hours(hours_per_year, name, year, hours) do
    years_map = hours_per_year[name]
    years_map = Map.put(years_map, year, years_map[year] + hours)
    Map.put(hours_per_year, name, years_map)
  end

  def report_acc do
    names = Enum.into(@names, %{}, &{&1, 0})

    hours = Enum.into(@months, %{}, &{&1, 0})
    hours_per_month = Enum.into(@names, %{}, &{&1, hours})

    years = Enum.into(2016..2020, %{}, &{&1, 0})
    hours_per_year = Enum.into(@names, %{}, &{&1, years})

    build_report(names, hours_per_month, hours_per_year)
  end

  defp build_report(all_hours, hours_per_month, hours_per_year) do
    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end
end
