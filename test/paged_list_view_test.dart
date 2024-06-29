import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paginationflutter/pagination_flutter.dart';
import 'package:mockito/mockito.dart';

import 'utils/paging_controller_utils.dart';
import 'utils/screen_size_utils.dart';

const _screenSize = Size(200, 500);

double get _itemHeight => _screenSize.height / pageSize;

void main() {
  group('Page requests', () {
    late MockPageRequestListener mockPageRequestListener;

    setUp(() {
      mockPageRequestListener = MockPageRequestListener();
    });

    testWidgets('Requests first page only once', (tester) async {
      final pagingController = PagingController<int, String>(
        firstPageKey: 1,
      );

      pagingController.addPageRequestListener(mockPageRequestListener);

      await _pumpPagedListView(
        tester: tester,
        pagingController: pagingController,
      );

      verify(mockPageRequestListener(1)).called(1);
    });

    testWidgets(
        'Requests second page immediately if the first page isn\'t enough',
        (tester) async {
      final controllerLoadedWithFirstPage =
          buildPagingControllerWithPopulatedState(
        PopulatedStateOption.ongoingWithOnePage,
      );

      controllerLoadedWithFirstPage.addPageRequestListener(
        mockPageRequestListener,
      );

      await _pumpPagedListView(
        tester: tester,
        pagingController: controllerLoadedWithFirstPage,
      );

      verify(mockPageRequestListener(2)).called(1);
    });

    testWidgets('Doesn\'t request a page unnecessarily', (tester) async {
      tester.applyPreferredTestScreenSize();

      final pagingController = buildPagingControllerWithPopulatedState(
        PopulatedStateOption.ongoingWithTwoPages,
      );
      pagingController.addPageRequestListener(mockPageRequestListener);

      await _pumpPagedListView(
        tester: tester,
        pagingController: pagingController,
      );

      verifyZeroInteractions(mockPageRequestListener);
    });

    testWidgets('Requests a new page on scroll', (tester) async {
      tester.applyPreferredTestScreenSize();

      final pagingController = buildPagingControllerWithPopulatedState(
        PopulatedStateOption.ongoingWithTwoPages,
      );
      pagingController.addPageRequestListener(mockPageRequestListener);

      await _pumpPagedListView(
        tester: tester,
        pagingController: pagingController,
      );

      await tester.scrollUntilVisible(
        find.text(
          secondPageItemList[5],
        ),
        _itemHeight,
      );

      verify(mockPageRequestListener(3)).called(1);
    });
  });

  testWidgets(
      'Inserts separators between items if a [separatorBuilder] is specified',
      (tester) async {
    final controllerLoadedWithFirstPage =
        buildPagingControllerWithPopulatedState(
      PopulatedStateOption.ongoingWithOnePage,
    );
    tester.applyPreferredTestScreenSize();

    await _pumpPagedListView(
      tester: tester,
      pagingController: controllerLoadedWithFirstPage,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
      ),
    );

    final separatorFinder = find.byType(Divider);
    expect(separatorFinder, findsNWidgets(pageSize - 1));
  });

  group('Appends indicators to the item list', () {
    testWidgets('Appends the new page progress indicator to the list items',
        (tester) async {
      tester.applyPreferredTestScreenSize();

      final pagingController = buildPagingControllerWithPopulatedState(
        PopulatedStateOption.ongoingWithOnePage,
      );

      final customIndicatorKey = UniqueKey();
      final customNewPageProgressIndicator = CircularProgressIndicator(
        key: customIndicatorKey,
      );

      await _pumpPagedListView(
        tester: tester,
        pagingController: pagingController,
        newPageProgressIndicator: customNewPageProgressIndicator,
      );

      await tester.scrollUntilVisible(
        find.byKey(customIndicatorKey),
        _itemHeight,
      );

      expectWidgetToHaveScreenWidth(
        customIndicatorKey,
        tester,
      );
    });

    testWidgets('Appends the new page error indicator to the list items',
        (tester) async {
      tester.applyPreferredTestScreenSize();

      final pagingController = buildPagingControllerWithPopulatedState(
        PopulatedStateOption.errorOnSecondPage,
      );

      final customIndicatorKey = UniqueKey();
      final customNewPageErrorIndicator = Text(
        'Error',
        key: customIndicatorKey,
      );

      await _pumpPagedListView(
        tester: tester,
        pagingController: pagingController,
        newPageErrorIndicator: customNewPageErrorIndicator,
      );

      await tester.scrollUntilVisible(
        find.byKey(customIndicatorKey),
        _itemHeight,
      );

      expectWidgetToHaveScreenWidth(
        customIndicatorKey,
        tester,
      );
    });

    testWidgets('Appends the no more items indicator to the list items',
        (tester) async {
      tester.applyPreferredTestScreenSize();

      final pagingController = buildPagingControllerWithPopulatedState(
        PopulatedStateOption.completedWithOnePage,
      );

      final customIndicatorKey = UniqueKey();
      final customNoMoreItemsIndicator = Text(
        'No More Items',
        key: customIndicatorKey,
      );

      await _pumpPagedListView(
        tester: tester,
        pagingController: pagingController,
        noMoreItemsIndicator: customNoMoreItemsIndicator,
      );

      await tester.scrollUntilVisible(
        find.byKey(customIndicatorKey),
        _itemHeight,
      );

      expectWidgetToHaveScreenWidth(
        customIndicatorKey,
        tester,
      );
    });
  });
}

class MockPageRequestListener extends Mock {
  void call(int pageKey);
}

Future<void> _pumpPagedListView({
  required WidgetTester tester,
  required PagingController<int, String> pagingController,
  IndexedWidgetBuilder? separatorBuilder,
  Widget? newPageProgressIndicator,
  Widget? newPageErrorIndicator,
  Widget? noMoreItemsIndicator,
}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: separatorBuilder == null
              ? PagedListView(
                  pagingController: pagingController,
                  builderDelegate: PagedChildBuilderDelegate<String>(
                    singleitemBuilder: _buildItem,
                    newPageProgressIndicatorWidget:
                        newPageProgressIndicator != null
                            ? (context) => newPageProgressIndicator
                            : null,
                    newPageErrorIndicatorWidget: newPageErrorIndicator != null
                        ? (context) => newPageErrorIndicator
                        : null,
                    noMoreItemsIndicatorWidget: noMoreItemsIndicator != null
                        ? (context) => noMoreItemsIndicator
                        : null,
                  ),
                )
              : PagedListView.separated(
                  pagingController: pagingController,
                  builderDelegate: PagedChildBuilderDelegate<String>(
                    singleitemBuilder: _buildItem,
                    newPageProgressIndicatorWidget:
                        newPageProgressIndicator != null
                            ? (context) => newPageProgressIndicator
                            : null,
                    newPageErrorIndicatorWidget: newPageErrorIndicator != null
                        ? (context) => newPageErrorIndicator
                        : null,
                    noMoreItemsIndicatorWidget: noMoreItemsIndicator != null
                        ? (context) => noMoreItemsIndicator
                        : null,
                  ),
                  separatorBuilder: separatorBuilder,
                ),
        ),
      ),
    );

Widget _buildItem(
  BuildContext context,
  String item,
  int index,
) =>
    SizedBox(
      height: _itemHeight,
      child: Text(
        item,
      ),
    );
